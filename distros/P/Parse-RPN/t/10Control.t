#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 9;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ '1,IF,ok,THEN',                                            'ok',                                              'IF' ];
push @tests, [ '0,IF,ok,THEN',                                            '',                                                'IF' ];
push @tests, [ '1,IF,in_else,ELSE,in_if,THEN',                            'in_if',                                           'IF ELSE THEN' ];
push @tests, [ '0,IF,in_else,ELSE,in_if,THEN',                            'in_else',                                         'IF ELSE THEN' ];
push @tests, [ '0,a,!,##,b,BEGIN,XX,a,INC,a,@,4,>,WHILE,##,a,@,_,REPEAT', '## b XX ## 1 _ XX ## 2 _ XX ## 3 _ XX ## 4 _ XX', 'REPEAT ( WHILE )' ];
push @tests, [ '10,1,DO,_,LOOP',                                          '_ _ _ _ _ _ _ _ _ _',                             'LOOP' ];
push @tests, [ '10,1,DO,_T_,@,LOOP',                                      '1 2 3 4 5 6 7 8 9 10',                            'LOOP _T_ variable' ];
push @tests, [ '10,0,2,DO,_T_,@,+LOOP',                                   '0 2 4 6 8 10',                                    '+LOOP' ];
push @tests, [ '0,10,-2,DO,_T_,@,+LOOP',                                  '10 8 6 4 2 0',                                    '+LOOP (decrementing)' ];

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
