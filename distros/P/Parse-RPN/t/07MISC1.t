#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 17;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ '2.3333, 7.555555,%d %.2f, PRINTF', '2 7.56',     'PRINTF' ];
push @tests, [ '2004,06,70,a4 a2 c, PACK',         '200406F',    'PACK' ];
push @tests, [ '20040608,a4 a2 a2, UNPACK',        '2004 06 08', 'UNPACK' ];
push @tests, [ '5,ISNUM',                          '5 1',        'ISNUM' ];
push @tests, [ 'a,ISNUM',                          'a 0',        'ISNUM' ];
push @tests, [ '5,ISNUMD',                         1,            'ISNUMD' ];
push @tests, [ 'a,ISNUMD',                         0,            'ISNUMD' ];
push @tests, [ '5,ISINT',                          '5 1',        'ISINT' ];
push @tests, [ '5.5,ISINT',                        '5.5 0',      'ISINT' ];
push @tests, [ '5,ISINTD',                         1,            'ISINTD' ];
push @tests, [ '5.5,ISINTD',                       0,            'ISINTD' ];
push @tests, [ '0xAB,ISHEX',                       '0xAB 1',     'ISHEX' ];
push @tests, [ '0xAZ,ISHEX',                       '0xAZ 0',     'ISHEX' ];
push @tests, [ '#ffddee,ISHEX',                    '#ffddee 1',  'ISHEX' ];
push @tests, [ '0xAB,ISHEXD',                      1,            'ISHEXD' ];
push @tests, [ '0xAZ,ISHEXD',                      0,            'ISHEXD' ];
push @tests, [ '#ffddee,ISHEXD',                   1,            'ISHEXD' ];

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
