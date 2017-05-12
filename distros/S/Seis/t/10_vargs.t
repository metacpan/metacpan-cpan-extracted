use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile(<<'...'), '42 roads';
sub slurpy(*@a) {
    @a.join(' ');
}
my int $i = 42;
my str $s = 'roads';
slurpy($i, $s);
...

#   is compile(<<'...'), 'a,b,c';
#   sub foo(@a) { @a.join(",") }
#   my @b=< a b c >;
#   foo(@b)
#   ...

done_testing;

