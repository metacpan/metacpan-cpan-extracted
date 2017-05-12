use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'update';

$test->(
    desc    => 'no conditions',
    input   => [foo => ordered_hashref(bar => 'baz', hoge => 'fuga')],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ?, `hoge` = ?',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'no conditions (multi value)',
    input   => [foo => [ bar => 'baz', hoge => 'fuga' ]],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ?, `hoge` = ?',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'no conditions (scalar)',
    input   => [foo => [ bar => \'UNIX_TIMESTAMP()', hoge => 'fuga' ]],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = UNIX_TIMESTAMP(), `hoge` = ?',
        bind => [qw/fuga/],
    },
);

$test->(
    desc    => 'no conditions (ref-array)',
    input   => [foo => [ bar => \['UNIX_TIMESTAMP(?)', '2011-11-11'] ]],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = UNIX_TIMESTAMP(?)',
        bind => [qw/2011-11-11/],
    },
);

$test->(
    desc    => 'add where',
    input   => [foo => [ bar => 'baz' ], { hoge => 'fuga' }],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ? WHERE (`hoge` = ?)',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'add order_by',
    input   => [foo => [ bar => 'baz' ], { hoge => 'fuga' }, { order_by => 'xyz' }],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ? WHERE (`hoge` = ?) ORDER BY `xyz`',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'custom prefix',
    input   => [foo => [ bar => 'baz' ], undef, { prefix => 'UPDATE IGNORE' }],
    expects => {
        stmt => 'UPDATE IGNORE `foo` SET `bar` = ?',
        bind => [qw/baz/],
    },
);

$test->(
    desc  => 'where in empty hash',
    input => [
        foo => [ bar => 'baz' ], {},
    ],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ?',
        bind => [qw/baz/],
    },
);

$test->(
    desc  => 'where in empty array',
    input => [
        foo => [ bar => 'baz' ], [],
    ],
    expects => {
        stmt => 'UPDATE `foo` SET `bar` = ?',
        bind => [qw/baz/],
    },
);

done_testing;
