#!perl

use Test2::V0;

my %funcs;
use String::Interpolate::RE (
    strinterp => {
        -as  => 'noenv',
        opts => { useENV => 0, raiseundef => 1 }
    },
    strinterp => { -as => 'withenv' } );

local %ENV;
$ENV{a} = 'A';

like( dies { noenv( '$a' ) }, qr/undefined variable: a/ );

is( withenv( '$a' ), 'A' );

done_testing;
