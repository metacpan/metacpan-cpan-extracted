use strict;
use warnings;
use t::Util;
use Test::More;

my $test = mk_test 'insert';

$test->(
    desc    => 'hash',
    input   => [foo => ordered_hashref(bar => 'baz', hoge => 'fuga')],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `hoge`) VALUES (?, ?)',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'multi value in array',
    input   => [foo => [ bar => 'baz', hoge => 'fuga' ]],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`, `hoge`) VALUES (?, ?)',
        bind => [qw/baz fuga/],
    },
);

$test->(
    desc    => 'scalar in array',
    input   => [foo => [ bar => \'UNIX_TIMSTAMP()' ]],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`) VALUES (UNIX_TIMSTAMP())',
        bind => [],
    },
);

$test->(
    desc    => 'ref-array in array',
    input   => [foo => [ bar => \['UNIX_TIMSTAMP(?)', '2011-11-11 11:11:11'] ]],
    expects => {
        stmt => 'INSERT INTO `foo` (`bar`) VALUES (UNIX_TIMSTAMP(?))',
        bind => ['2011-11-11 11:11:11'],
    },
);

$test->(
    desc    => 'custom prefix',
    input   => [foo => { bar => 'baz' }, { prefix => 'INSERT IGNORE INTO' }],
    expects => {
        stmt => 'INSERT IGNORE INTO `foo` (`bar`) VALUES (?)',
        bind => [qw/baz/],
    },
);

done_testing;
