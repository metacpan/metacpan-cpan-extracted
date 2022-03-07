use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    crypto_sign_PUBLICKEYBYTES crypto_sign_SECRETKEYBYTES
    crypto_sign_BYTES crypto_sign_SEEDBYTES
    crypto_sign_keypair crypto_sign_seed_keypair
    randombytes_buf
    crypto_sign crypto_sign_open
    crypto_sign_detached crypto_sign_verify_detached
);

ok(crypto_sign_SECRETKEYBYTES, 'crypto_sign_SECRETKEYBYTES: got the constant');
ok(crypto_sign_BYTES, 'crypto_sign_BYTES: got the constant');
ok(crypto_sign_PUBLICKEYBYTES, 'crypto_sign_PUBLICKEYBYTES: got the constant');
ok(crypto_sign_SEEDBYTES, 'crypto_sign_SEEDBYTES: got the constant');

# combined, no seed
{
    my ($pub, $priv) = crypto_sign_keypair();
    is(length($pub), crypto_sign_PUBLICKEYBYTES, 'crypto_sign_keypair: pub is right length');
    is(length($priv), crypto_sign_SECRETKEYBYTES, 'crypto_sign_keypair: priv is right length');

    my $msg = "Here is the message, to be signed using a secret key, and to be verified using a public key";
    my $msg_signed = crypto_sign($msg, $priv);
    ok($msg_signed, 'crypto_sign: got a result');
    is(length($msg_signed) - length($msg), crypto_sign_BYTES, 'The message length is correct');

    my $open = crypto_sign_open($msg_signed, $pub);
    is($open, $msg, 'crypto_sign_open: Messages are equal');
}

# combined, with seed
{
    my $seed = randombytes_buf(crypto_sign_SEEDBYTES);
    my ($pub, $priv) = crypto_sign_seed_keypair($seed);
    is(length($pub), crypto_sign_PUBLICKEYBYTES, 'crypto_sign_seed_keypair: pub is right length');
    is(length($priv), crypto_sign_SECRETKEYBYTES, 'crypto_sign_seed_keypair: priv is right length');

    my $msg = "Here is the message, to be signed using a seeded secret key, and to be verified using a public key";
    my $msg_signed = crypto_sign($msg, $priv);
    ok($msg_signed, 'crypto_sign: got a result');
    is(length($msg_signed) - length($msg), crypto_sign_BYTES, 'The message length is correct');

    my $open = crypto_sign_open($msg_signed, $pub);
    is($open, $msg, 'crypto_sign_open: Messages are equal');
}

# detached, no seed
{
    my ($pub, $priv) = crypto_sign_keypair();
    is(length($pub), crypto_sign_PUBLICKEYBYTES, 'crypto_sign_keypair: pub is right length');
    is(length($priv), crypto_sign_SECRETKEYBYTES, 'crypto_sign_keypair: priv is right length');

    my $msg = "Here is the message, to be signed using a secret key, and to be verified using a public key";
    my $signature = crypto_sign_detached($msg, $priv);
    ok($signature, 'crypto_sign_detached: got a result');
    is(length($signature), crypto_sign_BYTES, 'The signature length is correct');

    my $verified = crypto_sign_verify_detached($signature, $msg, $pub);
    ok($verified, 'crypto_sign_verify_detached: Message verified');
}


done_testing();
