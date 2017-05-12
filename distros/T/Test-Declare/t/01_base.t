use strict;
use warnings;
use Test::Declare;

plan tests => blocks;

my $foo;
describe 'base test' => run {
    init {
        $foo = 'foo';
    };
    test 'test block' => run {
        is 'foo', $foo;
    };
    cleanup {
        $foo = undef;
    };
};

describe 'base test' => run {
    test 'foo is undefined value' => run {
        is $foo, undef;
    };
};

