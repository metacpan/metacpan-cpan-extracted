use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'insert_multi_from_hash';

$test->(
    desc => 'basic',
    input   => [
        foo => [
            ordered_hashref(bar => 'hoge', baz => 'fuga'),
            ordered_hashref(bar => 'fizz', baz => 'buzz'),
        ],
    ],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)',
        bind => [qw/hoge fuga fizz buzz/],
    },
);

$test->(
    desc => 'mismatch params',
    input   => [
        foo => [
            ordered_hashref(bar => 'hoge', baz => 'fuga'),
            ordered_hashref(bar => 'fizz', baz => 'buzz', xxx => 'yyy'),
            { },
        ],
    ],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?), (?, ?)',
        bind => [qw/hoge fuga fizz buzz/, undef, undef],
    },
);

$test->(
    desc => 'complex',
    input   => [
        foo => [
            ordered_hashref(bar => 'hoge', baz => \'NOW()'),
            ordered_hashref(bar => 'fuga', baz => \['UNIX_TIMESTAMP(?)', '2012-12-12']),
        ],
    ],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `baz`) VALUES (?, NOW()), (?, UNIX_TIMESTAMP(?))',
        bind => [qw/hoge fuga 2012-12-12/],
    },
);

$test->(
    desc => 'insert ignore',
    input   => [
        foo => [
            ordered_hashref(bar => 'hoge', baz => 'fuga'),
            ordered_hashref(bar => 'fizz', baz => 'buzz'),
        ],
        { prefix => 'INSERT IGNORE INTO' },
    ],
    expects => {
        stmt => 'INSERT IGNORE INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)',
        bind => [qw/hoge fuga fizz buzz/],
    },
);

$test->(
    desc => 'on duplicate key update',
    input   => [
        foo => [
            ordered_hashref(bar => 'hoge', baz => 'fuga'),
            ordered_hashref(bar => 'fizz', baz => 'buzz'),
        ],
        { update => { bar => 'piyo' } },
    ],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?) ON DUPLICATE KEY UPDATE `bar` = ?',
        bind => [qw/hoge fuga fizz buzz piyo/],
    },
);

done_testing;
