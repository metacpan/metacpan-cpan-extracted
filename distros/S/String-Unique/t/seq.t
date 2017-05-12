#!/usr/bin/perl

use strict;
use Test::More tests => 10;
use lib ( './lib', '../lib' );
use String::Unique;

#BEGIN {
#	use_ok( 'String::Unique' );
#}
my $stringGen = String::Unique->new(
    {
        characterCount => 12,
        salt           => 'ua',
        date           => 'May 19, 2008'
    }
);
ok( $stringGen->getNextString('January 26 1987') eq '43HE5SB42BAQ' );
ok( $stringGen->getNextString('January 26 1987') eq 'JFQFXCWHDFCS' );
ok( $stringGen->getNextString('January 26 1987') eq '3MW7P9WMLJMC' );
ok( $stringGen->getNextString('January 26 1987') eq '8FZ19361FCGB' );
ok( $stringGen->getNextString('January 26 1987') eq 'XY54OPIO5CO2' );
ok( $stringGen->getNextString('January 26 1987') eq 'K4XC9LTQYPH8' );
ok( $stringGen->getNextString('January 26 1987') eq 'SB0180ARVX3L' );
ok( $stringGen->getNextString('January 26 1987') eq 'A7BY2SVCR2H4' );
ok( $stringGen->getNextString('January 26 1987') eq 'B0MIBG3KJWR3' );
ok( $stringGen->getNextString('January 26 1987') eq '1LLOA2SSPY6U' );
