#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 11;
use FindBin;
use lib "$FindBin::Bin/../lib";
$ENV{ TZ } = 'EST';
use Parse::RPN;

#########################
sub Test
{
    my $a = shift;
    my $b = shift;
    my $c = $a / $b;

    return $c;
}

sub Test1
{
    my $a = shift;
    return scalar reverse $a;
}

sub Test2
{
    return "default_value";
}

my %S = (
    bytesin  => 100,
    bytesout => 222,
    name     => 'eth0',
    mac      => 0xccaabbff,
    extra    => {
        a => 'azerty',
        b => 'test',
        c => 'qwerty'
    },
    extra1 => [ 'azerty1', 'test1' ]
);

my @T = qw( test1 test2 Test3 TEST4 );

my $s = \%S;

my $scal = 1.23456789;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'print( scalar (localtime(1377867665)));,PERL', 'Fri Aug 30 08:01:05 2013',               'PERL' ];
push @tests, [ ':,print 1377867665,PERL',                      '1377867665',                             'PERL' ];
push @tests, [ 'test,:,10,2,Test,PERLFUNC',                    'test 0.2',                               'PERLFUNC' ];
push @tests, [ 'test,Test2,PERLFUNC0',                         'test default_value',                     'PERLFUNC' ];
push @tests, [ 'test,5,6,2,Test,PERLFUNCX',                    'test 1.2',                               'PERLFUNCX' ];
push @tests, [ 'test,123,Test1,PERLFUNC1',                     'test 321',                               'PERLFUNC1' ];
push @tests, [ '{@T},PERLVAR',                                 '# test1 # test2 # Test3 # TEST4 #',      'PERLVAR' ];
push @tests, [ '{$s}->{mac},PERLVAR',                          0xccaabbff,                               'PERLVAR' ];
push @tests, [ '{$s}->{extra}->{a},PERLVAR',                   'azerty', 'PERLVAR' ];
push @tests, [ '{$scal},PERLVAR',                              '1.23456789',                             'PERLVAR' ];
push @tests, [ '{$scal1},PERLVAR',                              '',                             'PERLVAR' ];

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

