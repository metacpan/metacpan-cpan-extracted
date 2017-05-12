use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'format';

$test->(
    desc    => 'basic',
    input   => [
        'SELECT %c FROM %t WHERE %w',
        [qw/bar baz/], 'foo', { hoge => 'fuga' },
    ],
    expects => {
        stmt => 'SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?)',
        bind => [qw/fuga/],
    },
);

done_testing;
