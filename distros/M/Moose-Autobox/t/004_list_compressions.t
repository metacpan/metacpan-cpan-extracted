use strict;
use warnings;

use Test::More tests => 4;

use Moose::Autobox;

is_deeply(
[ 1 .. 5 ]->map(sub { $_ * $_ }),
[ 1, 4, 9, 16, 25 ],
'... got the expected return values');

is_deeply(
[ 1 .. 5 ]->map(sub { $_ * $_ })->do(sub { $_->zip($_) }),
[ [1, 1], [4, 4], [9, 9], [16, 16], [25, 25] ],
'... got the expected return values');

is( # sprintf an array ...
[ 1 .. 5 ]->sprintf("%d -> %d -> %d"),
'1 -> 2 -> 3',
'... got the sprintf-ed values');

is( # sprintf an array ...
[ 1 .. 5 ]->do(sub {
    $_->sprintf(
        $_->keys
          ->map(sub { '%d (' . $_ . ')' })
          ->join(' -> '))
}),
'1 (0) -> 2 (1) -> 3 (2) -> 4 (3) -> 5 (4)',
'... got a more elaboratly sprintf-ed values');

