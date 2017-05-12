use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'insert_on_duplicate';

$test->(
    desc  => 'basic',
    input => [
        'foo',
        ordered_hashref(bar => 'hoge', baz => 'fuga'),
        ordered_hashref(bar => \'VALUES(bar)', baz => 'piyo'),
    ],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `bar` = VALUES(bar), `baz` = ?',
        bind => [qw/hoge fuga piyo/],
    },
);

done_testing;
