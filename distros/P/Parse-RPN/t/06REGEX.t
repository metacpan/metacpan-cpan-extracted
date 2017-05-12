#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 15;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'aa_b_c_ddd_e_ff,_,SPLIT',                      'aa b c ddd e ff', 'SPLIT' ];
push @tests, [ '11a22A33a44A55,a,SPLIT',                       '11 22A33 44A55',  'SPLIT' ];
push @tests, [ 'aa#AA_b#B_c#C_ddd#DDD_e#E,_,#,x,y,SPLIT2,x,@', 'aa b c ddd e',    'SPLIT2' ];
push @tests, [ 'y,@',                                          'AA B C DDD E',    'SPLIT2' ];
push @tests, [ '11a22A33a44A55,a,SPLITI',                      '11 22 33 44 55',  'SPLITI' ];
push @tests, [ 'aabcadAbaaf,a,PAT',                            'a a a a a',       'PAT' ];
push @tests, [ 'aabcadAbaaf,a,PATI',                           'a a a A a a',     'PAT' ];
push @tests, [ 'abcdef,a,TPAT',                                1,                 'TPAT' ];
push @tests, [ 'abcdef,z,TPAT',                                0,                 'TPAT' ];
push @tests, [ 'abcdef,A,TPATI',                               1,                 'TPATI' ];
push @tests, [ 'abcdef,Z,TPATI',                               0,                 'TPATI' ];
push @tests, [ 'abacdABACD,A,xx,SPAT',                         'abacdxxBACD',     'SPAT' ];
push @tests, [ 'abacdABACD,A,xx,SPATI',                        'xxbacdABACD',     'STPATI' ];
push @tests, [ 'abacdABACD,A,xx,SPATG',                        'abacdxxBxxCD',    'SPATG' ];
push @tests, [ 'abacdABACD,a,xx,SPATGI',                       'xxbxxcdxxBxxCD',  'SPATGI' ];

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
