#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw/encode_base64url decode_base64url/;
use Crypt::PK::ECC;
use Crypt::KeyDerivation qw(hkdf);
use Crypt::AuthEnc::GCM qw(gcm_decrypt_verify);
use File::Raw::JSON qw(file_json_decode);
use VAPID ();
use Punk ();
use Punk::Plugin::Push ();

# RFC 8291's own worked example is asserted in VAPID's suite, where the
# arithmetic lives. What is proved here is the WIRING: that this plugin hands
# VAPID the right subscription keys and puts the resulting record on the wire
# unaltered.
#
# So the test plays the receiver. It generates a subscription whose private key
# it keeps, takes the body the plugin produced, and decrypts it the way a
# browser would. If the plugin passed the wrong key, swapped the two public
# keys in the context, or touched the bytes afterwards, this cannot pass.

our ($PUB, $PRIV) = VAPID::generate_vapid_keys();
our %OPTS = (subject => 'mailto:ops@example.com',
             public_key => $PUB, private_key => $PRIV,
             guard => sub { 1 });

{
    package TFake::Res;    sub new { bless { %{$_[1]} }, $_[0] } sub status { 201 }
    package TFake::Future; sub new { bless {}, shift } sub get { TFake::Res->new({}) }
    package TFake::UA;
    sub new  { bless { calls => [] }, shift }
    sub post { my ($s,$u,%o)=@_; push @{$s->{calls}}, {url=>$u,%o}; TFake::Future->new }
    sub last_body { $_[0]{calls}[-1]{body} }
}

eval <<'PERL' or die $@;
package PushEnc;
use Punk;
host 'https://example.com';
plugin 'Push' => { %main::OPTS };
1;
PERL
PushEnc->to_app;
my $app = PushEnc->punk_app;

my $ua = TFake::UA->new;
Punk::Plugin::Push->config_for($app)->{ua} = $ua;

# A subscription we hold both halves of, so we can play the browser.
my $ua_key = Crypt::PK::ECC->new;
$ua_key->generate_key('prime256v1');
my $auth_secret = join '', map { chr rand 256 } 1 .. 16;

my $subscription = {
    endpoint => 'https://push.example.net/p/1',
    keys => { p256dh => encode_base64url($ua_key->export_key_raw('public')),
              auth   => encode_base64url($auth_secret) },
};

# What a browser does with the body, per RFC 8291 section 3.4 over RFC 8188.
sub decrypt {
    my ($body) = @_;

    my $salt   = substr $body, 0, 16;
    my $rs     = unpack 'N', substr($body, 16, 4);
    my $idlen  = unpack 'C', substr($body, 20, 1);
    my $as_pub = substr $body, 21, $idlen;
    my $sealed = substr $body, 21 + $idlen;

    my $as = Crypt::PK::ECC->new->import_key_raw($as_pub, 'prime256v1');
    my $ecdh = $ua_key->shared_secret($as);

    my $ikm = hkdf($ecdh, $auth_secret, 'SHA256', 32,
        "WebPush: info\x00" . $ua_key->export_key_raw('public') . $as_pub);
    my $cek   = hkdf($ikm, $salt, 'SHA256', 16, "Content-Encoding: aes128gcm\x00");
    my $nonce = hkdf($ikm, $salt, 'SHA256', 12, "Content-Encoding: nonce\x00");

    my $ct  = substr($sealed, 0, length($sealed) - 16);
    my $tag = substr($sealed, -16);
    my $plain = gcm_decrypt_verify('AES', $cek, $nonce, '', $ct, $tag);
    return ($plain, $rs, $idlen);
}

# ---- the record a browser receives -----------------------------------------

{
    my $payload = { title => 'Your report is ready', body => 'Three pages.',
                    url => '/reports/2026-09' };
    Punk::Plugin::Push->send_to($app, $subscription, $payload);

    my $body = $ua->last_body;
    ok(defined $body, 'a body was put on the wire');

    my ($plain, $rs, $idlen) = decrypt($body);
    ok(defined $plain,
        'the receiver decrypts it with its own private key - so the plugin '
      . 'used the subscription keys it was given');
    is($rs, 4096, 'the record size in the header');
    is($idlen, 65, 'the key id is a 65-byte uncompressed point');

    is(substr($plain, -1), "\x02",
        'the plaintext ends with the RFC 8188 last-record delimiter');

    # Copied into a plain scalar first: substr passed straight into an XS
    # call yields an lvalue-magic scalar, which yyjson reads as empty.
    my $json = substr $plain, 0, -1;
    my $got = file_json_decode($json);
    is_deeply($got, $payload, 'and decodes to exactly the payload sent');
}

# ---- a string payload is sent as it stands ---------------------------------

{
    Punk::Plugin::Push->send_to($app, $subscription, 'just a string');
    my ($plain) = decrypt($ua->last_body);
    is(substr($plain, 0, -1), 'just a string',
        'a string payload is not JSON-wrapped');
}

# ---- non-ASCII survives the round trip -------------------------------------

{
    my $payload = { title => "Caf\x{e9} \x{263a}" };
    Punk::Plugin::Push->send_to($app, $subscription, $payload);
    my ($plain) = decrypt($ua->last_body);
    my $json = substr $plain, 0, -1;
    my $got = file_json_decode($json);
    is($got->{title}, "Caf\x{e9} \x{263a}",
        'a character string arrives as the same characters');
}

# ---- every send is fresh ---------------------------------------------------
#
# The ephemeral key and salt are per message. Two sends of one payload to one
# subscription must differ, or the relationship between them leaks.

{
    Punk::Plugin::Push->send_to($app, $subscription, { t => 1 });
    my $a = $ua->last_body;
    Punk::Plugin::Push->send_to($app, $subscription, { t => 1 });
    my $b = $ua->last_body;

    isnt($a, $b, 'two sends of one payload differ');
    isnt(substr($a, 0, 16), substr($b, 0, 16), '  a fresh salt');
    isnt(substr($a, 21, 65), substr($b, 21, 65), '  and a fresh ephemeral key');
    is(length($a), length($b), '  but the same length');

    # both still decrypt, which is what makes the freshness harmless
    my ($pa) = decrypt($a);
    my ($pb) = decrypt($b);
    is($pa, $pb, '  and both decrypt to the same plaintext');
}

# ---- the wrong subscription cannot read it ---------------------------------

{
    my $other = Crypt::PK::ECC->new;
    $other->generate_key('prime256v1');
    Punk::Plugin::Push->send_to($app, {
        endpoint => 'https://push.example.net/p/2',
        keys => { p256dh => encode_base64url($other->export_key_raw('public')),
                  auth   => encode_base64url(join '', map { chr rand 256 } 1..16) },
    }, { t => 'secret' });

    my $plain = eval { (decrypt($ua->last_body))[0] };
    ok(!defined $plain || $plain !~ /secret/,
        'a body encrypted for another subscription does not decrypt with ours');
}

done_testing;
