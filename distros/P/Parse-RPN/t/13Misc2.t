#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 24;
use FindBin;
use lib "$FindBin::Bin/../lib";
$ENV{TZ}='EST';
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'TICK',                                                                                time,                                      'TIME' ];
push @tests, [ '1378031372,LTIME',                                                                   '32 29 5 1 8 113 0 243 0',                  'LTIME' ];
push @tests, [ '1378031372,GTIME',                                                                   '32 29 10 1 8 113 0 243 0',                 'GTIME' ];
push @tests, [ '1378031372,HLTIME',                                                                  'Sun Sep  1 05:29:32 2013',                 'HLTIME' ];
push @tests, [ '1378031372,HGTIME',                                                                  'Sun Sep  1 10:29:32 2013',                 'HGTIME' ];
push @tests, [ '08-Feb-2013,HTTPTIME,CHOMP',                                                               '1360299600',                               'HTTPTIME' ];
push @tests, [ '1234567890,SPACE',                                                                   '1 234 567 890',                            'SPACE' ];
push @tests, [ '1234567890,DOT',                                                                     '1.234.567.890',                            'DOT' ];
push @tests, [ '1234567890,NORM',                                                                    '1.23 G',                                   'NORM' ];
push @tests, [ '1234567890,NORM2',                                                                   '1.15 G',                                   'NORM2' ];
push @tests, [ '3.5 M,UNORM',                                                                        '3500000',                                  'UNORM' ];
push @tests, [ '3.5 M,UNORM2',                                                                       '3670016',                                  'UNORM2' ];
push @tests, [ '0x77,OCT',                                                                           '119',                                      'OCT' ];
push @tests, [ '0123,OCT',                                                                           '83',                                       'OCT' ];
push @tests, [ 'Hello World,STR2DDEC',                                                               '72.101.108.108.111.32.87.111.114.108.100', 'STR2DDEC' ];
push @tests, [ '72.101.108.108.111.32.87.111.114.108.100,DDEC2STR',                                  'Hello World',                              'DDEC2STR' ];
push @tests, [ 'mb,tb,gb,mb,kb,4,V,!!,12,9,6,3,4,R,!!,V,R,"TPATI",LOOKUP',                           '6',                                        'LOOKUP' ];
push @tests, [ '5,1,2,3,4,5,5,V,!!," "," ",ok," ",nok,5,R,!!,V,R,"<=",LOOKUPP',                      'nok',                                      'LOOKUPP' ];
push @tests, [ '3,1,2,3,4,5,5,V,!!,a,b,ok,d,nok,5,R,!!,"==",">",">",">","==",5,O,!!,V,R,O,LOOKUPOP', 'd',                                        'LOOKUPOP' ];
push @tests, [ '3,1,2,3,4,5,5,V,!!,a,b,ok,d,nok,5,R,!!,"<","<","<","<","<",5,O,!!,V,R,O,LOOKUPOPP',  'd',                                        'LOOKUPOPP' ];
push @tests, [ '48656c6c6f,HEX2OCTSTR',                                                              'Hello',                                    'HEX2OCTSTR' ];
push @tests, [ 'Hello,OCTSTR2HEX',                                                                   '48656c6c6f',                               'OCTSTR2HEX' ];
push @tests, [ '0,1,RAND,>=<',                                                                       '1',                                        'RAND' ];
push @tests, [ '0,10,10,LRAND,>=<',                                                                  '1',                                        'LRAND' ];

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
