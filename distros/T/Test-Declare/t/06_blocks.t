use strict;
use warnings;
use Test::Declare;

plan tests => blocks;

describe 'base test' => run {
    test 'test block' => run {
        like 'foo', qr/foo/;
        is 'foo', 'foo';
        is blocks, 3;
    };
};

