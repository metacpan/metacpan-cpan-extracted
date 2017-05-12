#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 32;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'a,b,SWAP',                                       'b a',                     'SWAP' ];
push @tests, [ 'a,b,OVER',                                       'a b a',                   'OVER' ];
push @tests, [ 'a,DUP',                                          'a a',                     'DUP' ];
push @tests, [ 'a,b,DDUP',                                       'a b a b',                 'DDUP' ];
push @tests, [ 'a,b,c,d,ROT',                                    'a c d b',                 'ROT' ];
push @tests, [ 'a,b,c,d,RROT',                                   'a d b c',                 'RROT' ];
push @tests, [ 'a,b,c,d,DEPTH',                                  'a b c d 4',               'DEPTH' ];
push @tests, [ 'a,b,c,d,POP',                                    'a b c',                   'POP' ];
push @tests, [ 'a,b,c,d,e,f,2,POPN',                             'a b c d',                 'POPN' ];
push @tests, [ 'a,b,c,d,e,f,4,ROLL',                             'a b d e f c',             'ROLL' ];
push @tests, [ 'a,b,c,d,e,f,4,PICK',                             'a b c d e f c',           'PICK' ];
push @tests, [ 'a,b,c,d,e,f,4,GET',                              'a b d e f c',             'GET' ];
push @tests, [ 'a,b,c,d,e,f,A,4,PUT',                            'a b c A d e f',           'PUT' ];
push @tests, [ 'a,b,c,d,e,f,A,-4,PUT',                           'a b c d e A f',           'PUT' ];
push @tests, [ 'a,b,c,d,e,f,g,2,3,DEL',                          'a b e f g',               'DEL' ];
push @tests, [ 'a,b,c,d,e,f,g,d,FIND',                           'a b c d e f g 4',         'FIND' ];
push @tests, [ 'a,b,c,d,e,f,g,d,FINDK',                          'd',                       'FINDK' ];
push @tests, [ 'az,aX,ay,ax,ap,x,SEARCH',                        'az aX ay ax ap 2',        'SEARCH' ];
push @tests, [ 'az,aX,ay,ax,ap,x,SEARCHI',                       'az aX ay ax ap 4',        'SEARCHI' ];
push @tests, [ 'az,aX,ay,ax,ap,ax,x,SEARCHA',                    '3 1',                     'SEARCHA' ];
push @tests, [ 'az,aX,ay,ax,ap,ax,x,SEARCHIA',                   '5 3 1',                   'SEARCHIA' ];
push @tests, [ 'az,aX,ay,ax,ap,ax,x,SEARCHK',                    'ax ax',                   'SEARCHK' ];
push @tests, [ 'az,aX,ay,ax,ap,ax,x,SEARCHIK',                   'aX ax ax',                'SEARCHIK' ];
push @tests, [ 'a,b,c,d,e,f,g,3,KEEP',                           'e',                       'KEEP' ];
push @tests, [ '3,A,!,a,b,c,d,e,f,g,A,KEEPV',                    'e',                       'KEEPV' ];
push @tests, [ '1,5,2,3,A,!!,a,b,c,d,e,f,g,i,8,B,!!,B,A,KEEPVV', 'i d g',                   'KEEPVV' ];
push @tests, [ 'a,b,c,d,e,f,g,2,3,KEEPN',                        'd e',                     'KEEPN' ];
push @tests, [ 'a,b,c,d,e,f,g,h,i,5,2,KEEPR',                    'a b c d h',               'KEEPR' ];
push @tests, [ 'a,b,c,d,e,f,g,h,i,j,7,3,2,KEEPRN',               'a b c g h i',             'KEEPRN' ];
push @tests, [ 'a,b,c,d,e,f,g,h,,i,5,3,PRESERVE',                'e f g',                   'PRESERVE' ];
push @tests, [ 'a,b,c,d,e,f,g,h,i,2,5,PRESERVE',                 'e f g h i a b',           'PRESERVE' ];
push @tests, [ 'a,b,c,d,e,f,g,h,,i,5,3,COPY',                    'a b c d e f g h i e f g', 'COPY' ];

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
