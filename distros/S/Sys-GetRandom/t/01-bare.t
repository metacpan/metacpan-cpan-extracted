use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Test::More;

use Sys::GetRandom qw(getrandom random_bytes GRND_NONBLOCK GRND_RANDOM);

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

{
    my %seen;
    my $template = "abcdefgh";
    for my $i (0 .. 15) {
        my $buf = $template;
        is getrandom($buf, 1, 0, $i), 1, "getrandom() of length 1 returns 1";
        is length($buf), $i + 1, "[$i] buffer is extended/truncated after getrandom()";
        $seen{chop $buf}++;
        my $padding = $i <= length($template) ? "" : "\0" x ($i - length $template);
        is $buf, substr($template, 0, length $buf) . $padding, "[$i] buffer contents are correct after being extended/truncated";
    }
    cmp_ok scalar keys(%seen), '>', 1, "random bytes are random";
}

is length(random_bytes 5), 5, "random_bytes(5) returns 5 bytes";

done_testing;
