#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 10;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ './t/sample,STAT,\s,SPLIT,8,KEEP',                                 '40',                'STAT' ];
push @tests, [ 'Hello,./t/sample,r,FH,OPEN,4,FH,GETC',                            'Hello test',        'OPEN + GETC' ];
push @tests, [ 'Hello,./t/sample,r,FH,OPEN,4,FH,GETCS',                           'Hello t e s t',     'GETCS' ];
push @tests, [ 'Hello,./t/sample,r,FH,OPEN,5,0,FH,SEEK,4,FH,GETCS',               'Hello f i l e',     'SEEK' ];
push @tests, [ 'Hello,./t/sample,r,FH,OPEN,FH,READLINE',                          "Hello test file\n", 'READLINE' ];
push @tests, [ 'Hello,./t/sample,r,FH,OPEN,FH,READLINE,CHOMP',                    'Hello test file',   'READLINE +CHOMP' ];
push @tests, [ './t/sample,r,FH,OPEN,FH,5,FH,GETC,FH,TELL',                       'FH test  5',        'TELL' ];
push @tests, [ 'Hello,./t/sample1,crw,FH,OPEN,1,FH,WRITE,-2,1,FH,SEEK,1,FH,GETC', 'l',                 'WRITE' ];
push @tests, [ 'A,b,C,Hello,world,and,universe,4,FH,WRITELINE',                   'A b C',             'WRITELINE' ];
push @tests, [ 'FH,CLOSE,./t/sample1,UNLINK',                                     '1',                 'UNLINK' ];

foreach ( @tests )
{
    my ( $test, $result, $type ) = @{ $_ };
    my $ret = rpn( $test );
    ok( $ret eq $result, " \t" . t_format( $type, 20 ) . "\t=>\t" . t_format( $test, 70 ) . " = " . ( $ret ) );
}

sub t_format
{
    my $val = shift;
    my $nbr = () = ( $val =~ /#/g );
    my $w   = shift // $WIDTH;
    my $tmp = ' ' x $w;
    substr( $tmp, 0, length( $val ) + $nbr, $val );
    return $tmp;
}
