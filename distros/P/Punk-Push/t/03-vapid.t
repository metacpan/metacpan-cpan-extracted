#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw/decode_base64url/;
use Crypt::PK::ECC;
use Crypt::JWT qw(decode_jwt);
use VAPID ();
use Punk ();
use Punk::Plugin::Push ();

# The RFC 8291 and RFC 8292 worked examples live in VAPID's own suite, which is
# where the arithmetic belongs. What is checked here is that this plugin drives
# it correctly: the right audience, the right claims, a signature that verifies
# against the configured key, and one token per push service.
#
# VAPID's own suite once asserted only that a header was truthy, which is how
# the "vapit" scheme name survived into a release. Nothing here is satisfied by
# a header merely existing.

our ($PUB, $PRIV) = VAPID::generate_vapid_keys();
our %OPTS = (subject => 'mailto:ops@example.com',
             public_key => $PUB, private_key => $PRIV,
             guard => sub { 1 });

eval <<'PERL' or die $@;
package PushVapid;
use Punk;
host 'https://example.com';
plugin 'Push' => { %main::OPTS };
1;
PERL
PushVapid->to_app;
my $app = PushVapid->punk_app;

sub header_for { Punk::Plugin::Push->_vapid_header($app, $_[0]) }

sub claims_of {
    my ($header) = @_;
    my ($t) = $header =~ /t=([^,]+)/;
    my $key = Crypt::PK::ECC->new->import_key_raw(decode_base64url($PUB),
                                                 'prime256v1');
    return decode_jwt(token => $t, key => $key);   # verifies ES256
}

# ---- the header's shape ----------------------------------------------------

{
    my $h = header_for('https://push.example.net');
    like($h, qr/\Avapid t=\S+, k=\S+\z/,
        'the RFC 8292 section 3 single-header form');
    unlike($h, qr/\Avapit/, '  and not the typo VAPID shipped until 2.00');
    unlike($h, qr/WebPush/, '  nor the draft-era WebPush scheme');

    my ($k) = $h =~ /k=(\S+)\z/;
    is($k, $PUB, 'the k parameter is the configured public key');
}

# ---- the token verifies, and says what it should ---------------------------

{
    my $h = header_for('https://push.example.net');
    my $c = eval { claims_of($h) };
    is($@, '', 'the token verifies with ES256 against the public key') or diag $@;

    is($c->{aud}, 'https://push.example.net', 'aud is the push service origin');
    is($c->{sub}, 'mailto:ops@example.com',   'sub is the configured subject');
    ok($c->{exp} > time,               'exp is in the future');
    ok($c->{exp} <= time + 24 * 3600,  'and no more than 24 hours out, which '
                                     . 'is the RFC 8292 ceiling');
}

# A token that does not verify is the failure this file exists to catch.
{
    my $h = header_for('https://push.example.net');
    my ($t) = $h =~ /t=([^,]+)/;
    my ($other, undef) = VAPID::generate_vapid_keys();
    my $wrong = Crypt::PK::ECC->new->import_key_raw(decode_base64url($other),
                                                    'prime256v1');
    local $@;
    eval { decode_jwt(token => $t, key => $wrong) };
    ok($@, 'the signature does not verify against somebody else\'s key');
}

# ---- one audience per push service -----------------------------------------
#
# A token minted for one service is not valid at another, and caching one
# across a fan-out is the bug that makes Firefox work and Chrome fail.

{
    for my $origin (qw(https://push.example.net https://updates.other.example)) {
        my $c = claims_of(header_for($origin));
        is($c->{aud}, $origin, "the token for $origin names it");
    }

    isnt(header_for('https://push.example.net'),
         header_for('https://updates.other.example'),
        'two services get two different tokens');
}

# A non-default port is part of the origin. No push service uses one today,
# which is exactly why dropping it would go unnoticed until one did.
{
    my $c = claims_of(header_for('https://push.example.net:8443'));
    is($c->{aud}, 'https://push.example.net:8443',
        'a non-default port is kept in the audience');
}

# ---- the cache -------------------------------------------------------------

{
    my $first  = header_for('https://push.example.net');
    my $second = header_for('https://push.example.net');
    is($first, $second, 'a second send to the same service reuses the token');

    my $cfg = Punk::Plugin::Push->config_for($app);
    ok($cfg->{jwt}{'https://push.example.net'}, 'which is cached by audience');

    # Near expiry it is reminted, or a long-lived worker would keep sending a
    # token the push service has started refusing.
    $cfg->{jwt}{'https://push.example.net'}{exp} = time + 60;
    my $third = header_for('https://push.example.net');
    isnt($third, $first, 'a token close to expiry is reminted');
}

# ---- the subject reaches the token -----------------------------------------

{
    local %OPTS = (%OPTS, subject => 'https://example.com/contact');
    eval <<'PERL' or die $@;
package PushVapidUrl;
use Punk;
host 'https://example.com';
plugin 'Push' => { %main::OPTS };
1;
PERL
    PushVapidUrl->to_app;
    my $h = Punk::Plugin::Push->_vapid_header(PushVapidUrl->punk_app,
                                              'https://push.example.net');
    my ($t) = $h =~ /t=([^,]+)/;
    my $key = Crypt::PK::ECC->new->import_key_raw(decode_base64url($PUB),
                                                  'prime256v1');
    my $c = decode_jwt(token => $t, key => $key);
    is($c->{sub}, 'https://example.com/contact',
        'an https subject is carried as well as a mailto: one');
}

done_testing;
