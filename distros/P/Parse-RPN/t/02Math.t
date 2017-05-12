#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 21;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'PI',                              3.1415926535898,  'PI' ];
push @tests, [ 'PI,2,/,SIN',                      1,                'SIN' ];
push @tests, [ 'PI,2,*,COS',                      1,                'COS ' ];
push @tests, [ 'PI,4,/,TAN',                      1,                'TAN' ];
push @tests, [ '0.785398163397447,CTAN',          1,                'CTAN' ];
push @tests, [ '2.71828182845905,LN',             1,                'LN' ];
push @tests, [ '-0.693147180559945,EXP',          0.5,              'EXP (Natural exponent)' ];
push @tests, [ '1,2,MIN',                         1,                'MIN' ];
push @tests, [ '1,2,MAX',                         2,                'MAX' ];
push @tests, [ '1,2,0,3,4,9,5,6,8,MINX',          0,                'MINX' ];
push @tests, [ '1,2,0,3,4,9,5,6,8,MAXX',          9,                'MAXX' ];
push @tests, [ '1,2,3,4,5,5,SUM',                 15,               'SUM' ];
push @tests, [ '1,2,3,4,5,6,7,8,8,STATS,_SUM_,@', 36,               'STATS _SUM_' ];
push @tests, [ '_MULT_,@',                        40320,            'STATS _MULT_' ];
push @tests, [ '_ARITH_MEAN_,@',                  4.5,              'STATS _ARITH_MEAN_' ];
push @tests, [ '_GEOM_MEAN_,@',                   3.76435059950313, 'STATS _GEOM_MEAN_' ];
push @tests, [ '_HARM_MEAN_,@',                   2.94349540078844, 'STATS _HARM_MEAN_' ];
push @tests, [ '_QUAD_MEAN_,@',                   14.2828568570857, 'STATS _QUAD_MEAN_' ];
push @tests, [ '_VARIANCE_,@',                    6,                'STATS _VARIANCE_' ];
push @tests, [ '_STD_DEV_,@',                     2.29128784747792, 'STATS _STD_DEV_' ];
push @tests, [ '_SAMPLE_STD_DEV_,@',              2.44948974278318, 'STATS _SAMPLE_STD_DEV_' ];

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
