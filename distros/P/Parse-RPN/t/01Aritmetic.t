#!/usr/bin/perl -w    

# $Id:  Exp $

use strict;
use 5.006;
use warnings;

use Test::More tests => 14;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ '2,3,+',       5,   'Addition' ];
push @tests, [ '4,2,-',       2,   'Subtraction' ];
push @tests, [ '5,6,*',       30,  'Multiplication' ];
push @tests, [ '75,3,/',      25,  'Division' ];
push @tests, [ '2,3,**',      8,   'Exponantiation' ];
push @tests, [ '5,1+',        6,   'Incrementation by 1' ];
push @tests, [ '5,1-',        4,   'Decrementation by 1' ];
push @tests, [ '5,2+',        7,   'Incrementation by 2' ];
push @tests, [ '5,2-',        3,   'Decrementation by 2' ];
push @tests, [ '10,3,MOD',    1,   'Modulo' ];
push @tests, [ '-10,+-',      10,  'Negate' ];
push @tests, [ '-10,ABS',     10,  'Modulo' ];
push @tests, [ '10.4,INT',    10,  'Integer' ];
push @tests, [ '10.4,REMAIN', 0.4, 'Remainder' ];

foreach ( @tests )
{
    my ( $test, $result, $type ) = @{ $_ };
    my $ret = rpn( $test );
    ok( $ret eq $result, " \t" . t_format( $type ) . "\t=>\t" . ( $test ) . "\t=\t" . t_format( $ret ) );
}

sub t_format
{
    my $val = shift;
    my $tmp = ' ' x $WIDTH;
    substr( $tmp, 0, length( $val ), $val );
    return $tmp;
}
