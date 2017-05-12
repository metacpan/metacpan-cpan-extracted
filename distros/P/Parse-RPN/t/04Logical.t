#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 26;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ '1,0,OR',   1, 'OR' ];
push @tests, [ '0,0,OR',   0, 'OR' ];
push @tests, [ '1,1,OR',   1, 'OR' ];
push @tests, [ '0,0,AND',  0, 'AND' ];
push @tests, [ '0,1,AND',  0, 'AND' ];
push @tests, [ '1,1,AND',  1, 'AND' ];
push @tests, [ '0,0,XOR',  0, 'XOR' ];
push @tests, [ '0,1,XOR',  1, 'XOR' ];
push @tests, [ '1,1,XOR',  0, 'XOR' ];
push @tests, [ 'a,1,XOR',  0, 'XOR' ];
push @tests, [ '0,0,NXOR', 0, 'NXOR' ];
push @tests, [ '0,1,NXOR', 1, 'NXOR' ];
push @tests, [ '1,1,NXOR', 0, 'NXOR' ];
push @tests, [ 'a,1,NXOR', 1, 'NXOR' ];
push @tests, [ '1,NOT',    0, 'NOT' ];
push @tests, [ '0,NOT',    1, 'NOT' ];
push @tests, [ '0,TRUE',   0, 'TRUE' ];
push @tests, [ 'TRUE',     0, 'TRUE' ];
push @tests, [ '1,TRUE',   1, 'TRUE' ];
push @tests, [ 'a,TRUE',   0, 'TRUE' ];
push @tests, [ '0,FALSE',  1, 'FALSE' ];
push @tests, [ 'FALSE',    1, 'FALSE' ];
push @tests, [ '1,FALSE',  0, 'FALSE' ];
push @tests, [ 'a,FALSE',  1, 'FALSE' ];
push @tests, [ '1,3,<<',   8, '<< bitwise shift left' ];
push @tests, [ '32,3,>>',  4, '>> bitwise shift right' ];

foreach ( @tests )
{
    my ( $test, $result, $type ) = @{ $_ };
    my $ret = rpn( $test );
    ok( $ret eq $result, " \t" . t_format( $type ) . "\t=>\t" . t_format( $test ) . "\t=\t" . ( $ret ) );
}

sub t_format
{
    my $val = shift;
    my $tmp = ' ' x $WIDTH;
    substr( $tmp, 0, length( $val ), $val );
    return $tmp;
}
