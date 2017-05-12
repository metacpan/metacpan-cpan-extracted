use strict;
use warnings;
use Test::Declare;

plan tests => blocks;

describe 'Test::Exception method test' => run {
    test 'dies_ok' => run {
        dies_ok {die 'dies_ok'};
    };
    test 'throws_ok' => run {
        throws_ok( sub {die 'throws_ok'} , qr/throws_ok/);
    };
}

