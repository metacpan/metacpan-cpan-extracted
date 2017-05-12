#!/usr/bin/perl

use strict;
use Test::More tests => 9;
use lib ( './lib', '../lib' );
use String::Unique;

# This test is intended to test the change of date after midnight
my $stringGen = String::Unique->new(
    {
        characterCount => 10,
        salt           => 'oL',
        date           => 'May 19, 2008'
    }
);
ok( $stringGen->getNextString('September 10 2000') eq 'DXXVOT55T4' );
ok( $stringGen->getNextString('September 10 2000') eq 'W7GJ9WEA6G' );
ok( $stringGen->getNextString('September 10 2000') eq 'MI5ZFYZ55J' );

# Simulate midnight
ok( $stringGen->getNextString('September 11 2000') eq '1WUMTFLXPO' );
ok( $stringGen->getNextString('September 11 2000') eq 'VMMWPI8F3C' );
ok( $stringGen->getNextString('September 11 2000') eq '85ECJL57X8' );

#Now see if we cleaned up after mignight ...
ok( $stringGen->getNextString('September 10 2000') eq 'DXXVOT55T4' );
ok( $stringGen->getNextString('September 10 2000') eq 'W7GJ9WEA6G' );
ok( $stringGen->getNextString('September 10 2000') eq 'MI5ZFYZ55J' );
