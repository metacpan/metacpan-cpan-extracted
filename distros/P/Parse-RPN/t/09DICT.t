#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 31;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'WORDS,LEN',                     '1584',               'WORDS' ];
push @tests, [ 'test,C,!,C,@',                  'test',               '! (set variable)' ];
push @tests, [ 'a,b,c,d,4,B,!!,B,@',            'a b c d',            '!!' ];
push @tests, [ '1,A,!,VARS',                    'A | B | C',          'VARS' ];
push @tests, [ 'B,SIZE',                        '4',                  'SIZE' ];
push @tests, [ 'B,@',                           'a b c d',            '@' ];
push @tests, [ 'B,2,IND',                       'c',                  'IND' ];
push @tests, [ 'B,@',                           'a b c d',            '@' ];
push @tests, [ 'B,POPV',                        'd',                  'POPV' ];
push @tests, [ 'B,@',                           'a b c',              'POPV @' ];
push @tests, [ 'B,SHIFTV',                      'a',                  'SHIFTV' ];
push @tests, [ 'B,@',                           'b c',                'SHIFTV @' ];
push @tests, [ 'A,@',                           '1',                  '@' ];
push @tests, [ 'A,INC,A,@',                     '2',                  'INC @' ];
push @tests, [ 'A,DEC,A,@',                     '1',                  'DEC @' ];
push @tests, [ 'A,UNSET,VARS',                  'B | C',              'UNSET' ];
push @tests, [ 't,B,!A,B,@',                    't b c',              '!A' ];
push @tests, [ 'q,r,s,3,B,!!A,B,@',             't b c q r s',        '!!A' ];
push @tests, [ 's,t,u,v,w,x,4,3,B,!!!',         's t w x',            '!!!' ];
push @tests, [ 'B,@',                           'u v',                '!!! @' ];
push @tests, [ '1,2,3,4,5,6,2,D,!!C',           '1 2 3 4 5 6',        '!!C' ];
push @tests, [ 'D,@',                           '5 6',                '!!C @' ];
push @tests, [ '10,11,12,13,14,15,2,D,!!CA',    '10 11 12 13 14 15',  '!!CA' ];
push @tests, [ 'D,@',                           '5 6 14 15',          '!!CA @' ];
push @tests, [ '20,21,22,23,24,25,4,2,D,!!!A',  '20 21 25',           '!!!A' ];
push @tests, [ 'D,@',                           '5 6 14 15 22 23 24', '!!!A @' ];
push @tests, [ '30,31,32,33,34,35,4,2,D,!!!C',  '30 31 32 33 34 35',  '!!!C' ];
push @tests, [ 'D,@',                           '32 33 34',           '!!!C @' ];
push @tests, [ '40,41,42,43,44,45,4,2,D,!!!CA', '40 41 42 43 44 45',  '!!!CA' ];
push @tests, [ 'D,@',                           '32 33 34 42 43 44',  '!!!CA @' ];
push @tests, [ ':,+,1+,PLUS,;,2,3,PLUS',        '6',                  '; (create words )' ];

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
