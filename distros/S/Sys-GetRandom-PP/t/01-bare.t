use strict;
use warnings 'all', FATAL => 'uninitialized';

use Test2::V0;

use Sys::GetRandom::PP qw(getrandom random_bytes GRND_NONBLOCK GRND_RANDOM);

{
    my $buf = [];
    is getrandom($buf, 1, GRND_RANDOM), 1, "getrandom() < 256 returns full result with GRND_RANDOM";
    is ref($buf), '', "getrandom() clobbers references";
    is length($buf), 1, "buffer has correct length";
}

is getrandom(my $buf_a, 13), 13, "getrandom() < 256 returns full result";
is length($buf_a), 13, "buffer has correct length";
is getrandom(my $buf_b, 13, 0), 13, "getrandom() < 256 returns full result";
is length($buf_b), 13, "buffer has correct length";

isnt $buf_a, $buf_b, "two random strings are different";

is length(random_bytes 5), 5, "random_bytes(5) returns 5 bytes";

done_testing;
