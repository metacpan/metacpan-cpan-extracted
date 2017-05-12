#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 45;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ '1,2,<',     1,  '<' ];
push @tests, [ '3,2,<',     0,  '<' ];
push @tests, [ '1,2,<=',    1,  '<=' ];
push @tests, [ '3,3,<=',    1,  '<=' ];
push @tests, [ '3,2,<=',    0,  '<=' ];
push @tests, [ '1,2,>',     0,  '>' ];
push @tests, [ '3,2,>',     1,  '>' ];
push @tests, [ '1,2,>=',    0,  '>=' ];
push @tests, [ '2,2,>=',    1,  '>=' ];
push @tests, [ '1,2,>=',    0,  '>=' ];
push @tests, [ '2,2,==',    1,  '==' ];
push @tests, [ '1,2,==',    0,  '==' ];
push @tests, [ '2,2,!=',    0,  '!=' ];
push @tests, [ '1,2,!=',    1,  '!=' ];
push @tests, [ '1,1,<=>',   0,  '<=>' ];
push @tests, [ '1,2,<=>',   -1, '<=>' ];
push @tests, [ '2,1,<=>',   1,  '<=>' ];
push @tests, [ '2,5,1,>=<', 0,  '>=<' ];
push @tests, [ '2,5,3,>=<', 1,  '>=<' ];
push @tests, [ '2,5,5,>=<', 1,  '>=<' ];
push @tests, [ '2,5,6,>=<', 0,  '>=<' ];
push @tests, [ '2,5,1,><',  0,  '><' ];
push @tests, [ '2,5,3,><',  1,  '><' ];
push @tests, [ '2,5,5,><',  0,  '><' ];
push @tests, [ '2,5,6,><',  0,  '><' ];
push @tests, [ '1,2,N<',    1,  'N<' ];
push @tests, [ '3,2,N<',    0,  'N<' ];
push @tests, [ 'a,2,N<',    0,  'N<' ];
push @tests, [ '1,2,N<=',   1,  'N<=' ];
push @tests, [ '3,2,N<=',   0,  'N<=' ];
push @tests, [ '2,2,N<=',   1,  'N<=' ];
push @tests, [ 'a,2,N<=',   0,  'N<=' ];
push @tests, [ '1,2,N>',    0,  'N>' ];
push @tests, [ '3,2,N>',    1,  'N>' ];
push @tests, [ 'a,2,N>',    0,  'N>' ];
push @tests, [ '1,2,N>=',   0,  'N>=' ];
push @tests, [ '3,2,N>=',   1,  'N>=' ];
push @tests, [ '2,2,N>=',   1,  'N>=' ];
push @tests, [ 'a,2,N>=',   0,  'N>=' ];
push @tests, [ 'a,2,N==',   0,  'N==' ];
push @tests, [ '1,2,N==',   0,  'N==' ];
push @tests, [ '2,2,N==',   1,  'N==' ];
push @tests, [ '2,2,N!=',   0,  'N!=' ];
push @tests, [ '1,2,N!=',   1,  'N!=' ];
push @tests, [ 'a,2,N!=',   0,  'N!=' ];
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
