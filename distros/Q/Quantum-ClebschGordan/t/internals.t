#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 89;
use Quantum::ClebschGordan;
$|=1;

my $x = Quantum::ClebschGordan->new();
ok( $x, "got object" );
is( ref($x), 'Quantum::ClebschGordan', 'got Quantum::ClebschGordan object' );
is_deeply( [ $x->state_names ], [qw/ j1 j2 m m1 m2 j /], "state_names" );

sub arr2str {
  return join ":", map { defined($_) ? $_ : '' } @_;
}
sub change_state {
  my ($obj, $var, $value, $check, $vars ) = @_;
  eval { $obj->$var( $value ) };
  my $line = "[line " . (caller())[2] . "]";
  if( ! defined $check ){  # expecting an error
    ok( $@, "$line got error setting '$var' to '$value'" );
  }else{
    is( $obj->get($var), $value, "$line '$var' set to '$value'" );
    is( $obj->__check_state(), $check, "__check_state ok" );
    is( arr2str($obj->get(qw/j1 j2 m m1 m2 j __coeff/)), arr2str(@$vars), "vars all match" );
  }
}
 
$x = Quantum::ClebschGordan->new();
is( $x->__check_state(), undef, "check_state()" );
#	    obj,  var, val,	chk,[j1, j2,	m,	m1,    m2,	j,	coeff ] );
change_state( $x, 'j1',	1,	-1, [ 1, undef,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	1,	-1, [ 1, 1,		undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'm',	1,	-1, [ 1, 1,		1,	undef, undef,	undef,	undef ] );
change_state( $x, 'm1',	1,	-1, [ 1, 1,		1,	1,     undef,	undef,	undef ] );
change_state( $x, 'm2',	0,	-1, [ 1, 1,		1,	1,     0,	undef,	undef ] );
change_state( $x, 'j',	1,	1, [ 1, 1,		1,	1,     0,	1,	'1/2' ] );
change_state( $x, 'm2',	1,	undef );

$x = Quantum::ClebschGordan->new();
change_state( $x, 'j1',	1,	-1, [ 1, undef,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	2,	undef );
change_state( $x, 'j2',	0,	undef );
change_state( $x, 'j2',	-1,	undef );
change_state( $x, 'j2',	0.5,	-1, [ 1, 0.5,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	'1/2',	-1, [ 1, '1/2',	undef,	undef, undef,	undef,	undef ] );

$x = Quantum::ClebschGordan->new();
change_state( $x, 'j1',	1,	-1, [ 1, undef,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	'1/2',	-1, [ 1, '1/2',	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'm',	'1/2',	-1, [ 1, '1/2',	'1/2',	undef, undef,	undef,	undef ] );
change_state( $x, 'm1',	0,	-1, [ 1, '1/2',	'1/2',	0,     undef,	undef,	undef ] );
change_state( $x, 'm2',	'1/2',	-1, [ 1, '1/2',	'1/2',	0,     '1/2',	undef,	undef ] );
change_state( $x, 'j',	'1/2',	1,  [ 1, '1/2',	'1/2',	0,     '1/2',	'1/2',	'-1/3' ] );

$x = Quantum::ClebschGordan->new();
change_state( $x, 'j1',	1,	-1, [ 1, undef,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	0.5,	-1, [ 1, 0.5,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'm',	0.5,	-1, [ 1, 0.5,	0.5,	undef, undef,	undef,	undef ] );
change_state( $x, 'm1',	0,	-1, [ 1, 0.5,	0.5,	0,     undef,	undef,	undef ] );
change_state( $x, 'm2',	0.5,	-1, [ 1, 0.5,	0.5,	0,     0.5,	undef,	undef ] );
change_state( $x, 'j',	0.5,	1,  [ 1, 0.5,	0.5,	0,     0.5,	0.5,	'-1/3' ] );

$x = Quantum::ClebschGordan->new();
change_state( $x, 'j1',	1,	-1, [ 1, undef,	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'j2',	'1/2',	-1, [ 1, '1/2',	undef,	undef, undef,	undef,	undef ] );
change_state( $x, 'm',	0.5,	-1, [ 1, '1/2',	0.5,	undef, undef,	undef,	undef ] );
change_state( $x, 'm1',	0,	-1, [ 1, '1/2',	0.5,	0,     undef,	undef,	undef ] );
change_state( $x, 'm2',	'1/2',	-1, [ 1, '1/2',	0.5,	0,     '1/2',	undef,	undef ] );
change_state( $x, 'j',	'1/2',	1,  [ 1, '1/2',	0.5,	0,     '1/2',	'1/2',	'-1/3' ] );

#eof#

