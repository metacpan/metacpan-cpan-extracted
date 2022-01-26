use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    randombytes_random randombytes_uniform randombytes_SEEDBYTES
    randombytes_buf randombytes_buf_deterministic
);

# diag("SIZE_MAX is: " . Sodium::FFI::SIZE_MAX);

# randombytes_random
ok(randombytes_SEEDBYTES, 'randombytes_SEEDBYTES: got the constant');
like(randombytes_random(), qr/^[0-9]+$/, 'randombytes_random: worked');
is(randombytes_uniform(1), 0, 'randombytes_uniform: upper limit less than 2 results zero');
ok(length(randombytes_buf(2)) == 2, 'randombytes_buf: length of 2 yielded two bytes');
ok(length(randombytes_buf(-1)) == 0, 'randombytes_buf: length of less than 1 yields empty string');

# randombytes_buf_deterministic
SKIP: {
    skip('randombytes_buf_deterministic implemented in libsodium >= v1.0.12', 1) unless Sodium::FFI::_version_or_better(1, 0, 12);
    my $len = 2;
    my $seed = "\x01" x randombytes_SEEDBYTES;
    my $bytes = randombytes_buf_deterministic($len, $seed);
    ok(length($bytes) == $len, 'randombytes_buf_deterministic: got a good byte string');
};

done_testing();
