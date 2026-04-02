#!/usr/bin/perl

use v5.10;
use strictures 2;
use autodie;

use Test2::V0 -no_srand => 1;
# use Test2::Plugin::BailOnFail; # bail out of testing on the first failure
use File::Temp;
use Digest::SHA qw(sha256_hex);

use Net::Nostr::Key;

my $CRYPTPKECC = Crypt::PK::ECC->new->generate_key('secp256k1');;

subtest 'new()' => sub {
    my $key = Net::Nostr::Key->new;
    ok($key->privkey_loaded, 'automatically generates new private key');

    $key = Net::Nostr::Key->new(privkey => \$CRYPTPKECC->export_key_der('private'));
    is($key->privkey_der, $CRYPTPKECC->export_key_der('private'), 'specify private key from constructor');
    ok($key->pubkey_loaded, 'automatically derives public key from private key');

    $key = Net::Nostr::Key->new(pubkey => \$CRYPTPKECC->export_key_der('public'));
    ok(($key->pubkey_loaded and not $key->privkey_loaded), 'load only a public key with \'pubkey\' constructor arg');

    ok(dies { my $key = Net::Nostr::Key->new(privkey => 12) }, 'die if passed invalid constructor key');
};

subtest 'schnorr_sign()' => sub {
    my $key = Net::Nostr::Key->new;
    my $msg = 'test message';
    my $sig = $key->schnorr_sign($msg);
    ok($sig, 'returns a signature');

    my $verifier = Crypt::PK::ECC::Schnorr->new(\$key->pubkey_der);
    ok($verifier->verify_message($msg, $sig), 'signature verifies with public key');
};

subtest 'POD: schnorr_sign returns 64 bytes' => sub {
    my $key = Net::Nostr::Key->new;
    my $sig = $key->schnorr_sign('hello');
    is(length($sig), 64, 'signature is 64 raw bytes');
};

subtest 'pubkey_hex and privkey_hex' => sub {
    my $key = Net::Nostr::Key->new;
    like($key->pubkey_hex, qr/^[0-9a-f]{64}$/, 'pubkey_hex is 64-char lowercase hex');
    like($key->privkey_hex, qr/^[0-9a-f]{64}$/, 'privkey_hex is 64-char lowercase hex');
};

subtest 'pubkey_raw and privkey_raw' => sub {
    my $key = Net::Nostr::Key->new;
    my $pub_raw = $key->pubkey_raw;
    is(length($pub_raw), 65, 'pubkey_raw is 65 bytes (uncompressed)');
    is(substr($pub_raw, 0, 1), "\x04", 'pubkey_raw starts with 04 prefix');

    my $priv_raw = $key->privkey_raw;
    is(length($priv_raw), 32, 'privkey_raw is 32 bytes');
};

subtest 'pubkey_pem and privkey_pem' => sub {
    my $key = Net::Nostr::Key->new;
    my $pub_pem = $key->pubkey_pem;
    like($pub_pem, qr/-----BEGIN PUBLIC KEY-----/, 'pubkey_pem has PEM header');
    like($pub_pem, qr/-----END PUBLIC KEY-----/, 'pubkey_pem has PEM footer');

    my $priv_pem = $key->privkey_pem;
    like($priv_pem, qr/-----BEGIN EC PRIVATE KEY-----/, 'privkey_pem has PEM header');
    like($priv_pem, qr/-----END EC PRIVATE KEY-----/, 'privkey_pem has PEM footer');
};

subtest 'POD: DER round-trip via constructor' => sub {
    my $key = Net::Nostr::Key->new;

    my $key2 = Net::Nostr::Key->new(pubkey => \$key->pubkey_der);
    is($key2->pubkey_hex, $key->pubkey_hex, 'pubkey DER round-trips');

    my $key3 = Net::Nostr::Key->new(privkey => \$key->privkey_der);
    is($key3->pubkey_hex, $key->pubkey_hex, 'privkey DER round-trips');
    ok($key3->privkey_loaded, 'privkey still loaded after round-trip');
};

subtest 'POD: pubkey-only key has pubkey_loaded but not privkey_loaded' => sub {
    my $key = Net::Nostr::Key->new;
    my $pub_only = Net::Nostr::Key->new(pubkey => \$key->pubkey_der);
    ok($pub_only->pubkey_loaded, 'pubkey_loaded is true');
    ok(!$pub_only->privkey_loaded, 'privkey_loaded is false');
};

subtest 'load private key from file' => sub {
    my $key = Net::Nostr::Key->new;
    my $tmp = File::Temp->new(SUFFIX => '.pem');
    print $tmp $key->privkey_pem;
    close $tmp;

    my $loaded = Net::Nostr::Key->new(privkey => $tmp->filename);
    ok($loaded->privkey_loaded, 'private key loaded from file');
    is($loaded->pubkey_hex, $key->pubkey_hex, 'pubkey matches original');
    is($loaded->privkey_hex, $key->privkey_hex, 'privkey matches original');
};

subtest 'load public key from file' => sub {
    my $key = Net::Nostr::Key->new;
    my $tmp = File::Temp->new(SUFFIX => '.pem');
    print $tmp $key->pubkey_pem;
    close $tmp;

    my $loaded = Net::Nostr::Key->new(pubkey => $tmp->filename);
    ok($loaded->pubkey_loaded, 'public key loaded from file');
    ok(!$loaded->privkey_loaded, 'no private key loaded');
    is($loaded->pubkey_hex, $key->pubkey_hex, 'pubkey matches original');
};

subtest 'load private key from DER file' => sub {
    my $key = Net::Nostr::Key->new;
    my $tmp = File::Temp->new(SUFFIX => '.der');
    binmode $tmp;
    print $tmp $key->privkey_der;
    close $tmp;

    my $loaded = Net::Nostr::Key->new(privkey => $tmp->filename);
    ok($loaded->privkey_loaded, 'private key loaded from DER file');
    is($loaded->pubkey_hex, $key->pubkey_hex, 'pubkey matches original');
};

subtest 'save_privkey writes PEM file and round-trips' => sub {
    my $key = Net::Nostr::Key->new;
    my $tmp = File::Temp->new(SUFFIX => '.pem');
    my $path = $tmp->filename;
    close $tmp;

    $key->save_privkey($path);
    ok(-f $path, 'file created');

    my $loaded = Net::Nostr::Key->new(privkey => $path);
    ok($loaded->privkey_loaded, 'private key loaded from saved file');
    is($loaded->pubkey_hex, $key->pubkey_hex, 'pubkey matches original');
    is($loaded->privkey_hex, $key->privkey_hex, 'privkey matches original');
};

subtest 'save_pubkey writes PEM file and round-trips' => sub {
    my $key = Net::Nostr::Key->new;
    my $tmp = File::Temp->new(SUFFIX => '.pem');
    my $path = $tmp->filename;
    close $tmp;

    $key->save_pubkey($path);
    ok(-f $path, 'file created');

    my $loaded = Net::Nostr::Key->new(pubkey => $path);
    ok($loaded->pubkey_loaded, 'public key loaded from saved file');
    ok(!$loaded->privkey_loaded, 'no private key loaded');
    is($loaded->pubkey_hex, $key->pubkey_hex, 'pubkey matches original');
};

subtest 'save_privkey croaks without privkey loaded' => sub {
    my $key = Net::Nostr::Key->new;
    my $pub_only = Net::Nostr::Key->new(pubkey => \$key->pubkey_der);
    ok(dies { $pub_only->save_privkey('/tmp/should_not_exist.pem') },
       'croaks when no private key loaded');
};

subtest 'constructor_keys' => sub {
    my @keys = Net::Nostr::Key->constructor_keys;
    is(\@keys, [qw(privkey pubkey)], 'constructor_keys returns privkey and pubkey');
};

###############################################################################
# sign_event and create_event
###############################################################################

use Net::Nostr::Event;

subtest 'sign_event signs an existing event' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = Net::Nostr::Event->new(
        pubkey  => $key->pubkey_hex,
        kind    => 1,
        content => 'unsigned',
        tags    => [],
    );
    ok(!$event->sig, 'event starts unsigned');

    my $sig = $key->sign_event($event);
    like($sig, qr/^[0-9a-f]{128}$/, 'returns 128-char hex signature');
    is($event->sig, $sig, 'sig set on event');
    ok($event->verify_sig($key), 'signature verifies');
};

subtest 'create_event builds and signs an event' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'hello nostr');

    isa_ok($event, 'Net::Nostr::Event');
    is($event->pubkey, $key->pubkey_hex, 'pubkey set from key');
    is($event->kind, 1, 'kind preserved');
    is($event->content, 'hello nostr', 'content preserved');
    like($event->id, qr/^[0-9a-f]{64}$/, 'id computed');
    like($event->sig, qr/^[0-9a-f]{128}$/, 'sig computed');
    ok($event->verify_sig($key), 'signature verifies');
};

subtest 'create_event accepts tags and created_at' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind       => 1,
        content    => 'tagged',
        tags       => [['t', 'nostr']],
        created_at => 1700000000,
    );
    is($event->tags, [['t', 'nostr']], 'tags preserved');
    is($event->created_at, 1700000000, 'created_at preserved');
};

done_testing;
