use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

arg first => (
    isa     => 'Str',
    comment => 'first',
);

arg rest => (
    isa     => 'Str',
    comment => 'grab the rest',
    greedy  => 1,
);

@ARGV = (qw/x/);
is_deeply optargs, { first => 'x' }, 'got a str';

@ARGV = (qw/k 1/);
is_deeply optargs, { first => 'k', rest => '1' }, 'one for one';

@ARGV = (qw/k 1 3.14 1 one=1/);
is_deeply optargs, { first => 'k', rest => '1 3.14 1 one=1' }, 'lots for one';

done_testing;
