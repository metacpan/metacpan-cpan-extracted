use warnings;
use Test::More;
use Sodium::FFI qw(
    crypto_box_SEALBYTES crypto_box_PUBLICKEYBYTES crypto_box_SECRETKEYBYTES
    crypto_box_MACBYTES crypto_box_NONCEBYTES crypto_box_SEEDBYTES
    crypto_box_BEFORENMBYTES
    randombytes_buf
    crypto_box_keypair crypto_box_seed_keypair crypto_scalarmult_base
    crypto_box_easy crypto_box_open_easy
);

# test the various constants
ok(crypto_box_SEALBYTES, 'crypto_box_SEALBYTES: got the constant');
ok(crypto_box_PUBLICKEYBYTES, 'crypto_box_PUBLICKEYBYTES: got the constant');
ok(crypto_box_SECRETKEYBYTES, 'crypto_box_SECRETKEYBYTES: got the constant');
ok(crypto_box_MACBYTES, 'crypto_box_MACBYTES: got the constant');
ok(crypto_box_NONCEBYTES, 'crypto_box_NONCEBYTES: got the constant');
ok(crypto_box_SEEDBYTES, 'crypto_box_SEEDBYTES: got the constant');
ok(crypto_box_BEFORENMBYTES, 'crypto_box_BEFORENMBYTES: got the constant');

# test scalarmult
{
    my ($pub, $priv) = crypto_box_keypair();
    is(length($pub), crypto_box_PUBLICKEYBYTES, 'crypto_box_keypair: pub is right length');
    is(length($priv), crypto_box_SECRETKEYBYTES, 'crypto_box_keypair: priv is right length');

    my $comp_pub = crypto_scalarmult_base($priv);
    is(length($comp_pub), crypto_box_PUBLICKEYBYTES, 'crypto_scalarmult_base: computed public key is right length');
    is($comp_pub, $pub, 'crypto_scalarmult_base: computed public key is same as original');
}

# combined, no seed
{
    my ($pub, $priv) = crypto_box_keypair();
    is(length($pub), crypto_box_PUBLICKEYBYTES, 'crypto_box_keypair: pub is right length');
    is(length($priv), crypto_box_SECRETKEYBYTES, 'crypto_box_keypair: priv is right length');

    my $msg = "test";
    my $nonce = randombytes_buf(crypto_box_NONCEBYTES);

    # crypto_box_easy
    my $cipher = crypto_box_easy($msg, $nonce, $pub, $priv);
    ok($cipher, 'crypto_box_easy: got the cipher text back');
    is(length($cipher), crypto_box_MACBYTES + length($msg), 'crypto_box_easy: cipher text is the right length');

    # crypto_box_open_easy
    my $decrypted = crypto_box_open_easy($cipher, $nonce, $pub, $priv);
    ok($decrypted, 'crypto_box_open_easy: got a response');
    is($decrypted, $msg, 'crypto_box_open_easy: got the correct response');
}

# combined, with seed
{
    my $seed = randombytes_buf(crypto_box_SEEDBYTES);
    my ($pub, $priv) = crypto_box_seed_keypair($seed);
    is(length($pub), crypto_box_PUBLICKEYBYTES, 'crypto_box_seed_keypair: pub is right length');
    is(length($priv), crypto_box_SECRETKEYBYTES, 'crypto_box_seed_keypair: priv is right length');

    my $msg = "test";
    my $nonce = randombytes_buf(crypto_box_NONCEBYTES);

    # crypto_box_easy
    my $cipher = crypto_box_easy($msg, $nonce, $pub, $priv);
    ok($cipher, 'crypto_box_easy: got the cipher text back');
    is(length($cipher), crypto_box_MACBYTES + length($msg), 'crypto_box_easy: cipher text is the right length');

    # crypto_box_open_easy
    my $decrypted = crypto_box_open_easy($cipher, $nonce, $pub, $priv);
    ok($decrypted, 'crypto_box_open_easy: got a response');
    is($decrypted, $msg, 'crypto_box_open_easy: got the correct response');
}

done_testing();
