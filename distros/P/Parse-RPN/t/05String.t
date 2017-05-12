#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 33;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'alpha,alpha,EQ',                  1,                'EQ' ];
push @tests, [ 'alpha,beta,EQ',                   0,                'EQ' ];
push @tests, [ 'alpha,alpha,NE',                  0,                'NE' ];
push @tests, [ 'alpha,beta,NE',                   1,                'NE' ];
push @tests, [ 'a,a,LT',                          0,                'LT' ];
push @tests, [ 'a,b,LT',                          1,                'LT' ];
push @tests, [ 'b,a,LT',                          0,                'LT' ];
push @tests, [ 'a,a,GT',                          0,                'GT' ];
push @tests, [ 'a,b,GT',                          0,                'GT' ];
push @tests, [ 'b,a,GT',                          1,                'GT' ];
push @tests, [ 'a,a,LE',                          1,                'LE' ];
push @tests, [ 'a,b,LE',                          1,                'LE' ];
push @tests, [ 'b,a,LE',                          0,                'LE' ];
push @tests, [ 'a,a,GE',                          1,                'GE' ];
push @tests, [ 'a,b,GE',                          0,                'GE' ];
push @tests, [ 'b,a,GE',                          1,                'GE' ];
push @tests, [ 'a,a,CMP',                         0,                'CMP' ];
push @tests, [ 'a,b,CMP',                         -1,               'CMP' ];
push @tests, [ 'b,a,CMP',                         1,                'CMP' ];
push @tests, [ 'alpha,LEN',                       5,                'LEN' ];
push @tests, [ 'a,b,CAT',                         'ab',             'CAT' ];
push @tests, [ 'a,b,c,d,e,f,g,3,CATN',            'a b c d gfe',    'CATN' ];
push @tests, [ 'a,b,c,d,CATALL',                  'abcd',           'CATALL' ];
push @tests, [ 'a,b,c,d,e,f,g,#,JOIN',            'a b c d e f#g',  'JOIN' ];
push @tests, [ 'a,b,c,d,e,f,g,#,3,JOINN',         'a b c d g#f#e',  'JOINN' ];
push @tests, [ 'a,b,c,d,e,f,g,#,JOINALL',         'a#b#c#d#e#f#g',  'JOINALL' ];
push @tests, [ 'a,4,REP',                         'aaaa',           'REP' ];
push @tests, [ 'alpha,REV',                       'ahpla',          'REV' ];
push @tests, [ 'test a simple string,7,6,SUBSTR', 'simple',         'SUBSTR' ];
push @tests, [ 'alpha,UC',                        'ALPHA',          'UC' ];
push @tests, [ 'ALPHA,LC',                        'alpha',          'LC' ];
push @tests, [ 'alpha,UCFIRST',                   'Alpha',          'UCFIRST' ];
push @tests, [ 'ALPHA,LCFIRST',                   'aLPHA',          'LCFIRST' ];


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
