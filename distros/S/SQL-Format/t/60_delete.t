use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'delete';

$test->(
    desc    => 'no conditions',
    input   => ['foo'],
    expects => {
        stmt => 'DELETE FROM `foo`',
        bind => [],
    },
);

$test->(
    desc    => 'add where',
    input   => ['foo', ordered_hashref(bar => 'baz', hoge => 'fuga')],
    expects => {
        stmt => 'DELETE FROM `foo` WHERE (`bar` = ?) AND (`hoge` = ?)',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'add order_by, limit',
    input   => ['foo', { bar => 'baz' }, { order_by => 'hoge', limit => 100 }],
    expects => {
        stmt => 'DELETE FROM `foo` WHERE (`bar` = ?) ORDER BY `hoge` LIMIT 100',
        bind => [qw/baz/],
    },
);

$test->(
    desc    => 'custom prefix',
    input   => ['foo', { bar => 'baz' }, { prefix => 'DELETE LOW_PRIORITY' }],
    expects => {
        stmt => 'DELETE LOW_PRIORITY FROM `foo` WHERE (`bar` = ?)',
        bind => [qw/baz/],
    },
);

$test->(
    desc  => 'where in empty hash',
    input => [foo => {}],
    expects => {
        stmt => 'DELETE FROM `foo`',
        bind => [],
    },
);

$test->(
    desc  => 'where in empty array',
    input => [foo => []],
    expects => {
        stmt => 'DELETE FROM `foo`',
        bind => [],
    },
);

done_testing;
