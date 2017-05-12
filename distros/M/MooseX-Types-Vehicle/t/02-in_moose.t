#!perl -T

use Test::More tests => 6;

package Vehc;
use Test::More;
BEGIN{ use_ok ( 'Moose' ) }
BEGIN{ use_ok ( 'MooseX::Types::Vehicle', qw/VIN17/ ) }

has 'vin' => ( isa => VIN17, is => 'ro' );
has 'vin_coerced' => ( isa => VIN17, is => 'ro', coerce => 1);

package main;
use Test::More;

new_ok ( 'Vehc', [{vin=>'3D7KS28C26G180041'}] );
new_ok ( 'Vehc', [{vin_coerced=>'3D7KS28C26G18OO4I  '}] );

eval { Vehc->new({ vin => '3D7KS28C26G18004I' }) };
like ( $@, qr/Invalid Vin: 3D7KS28C26G18004I/, 'Invalid uncoerced vin' );

{
	my $vehc = eval { Vehc->new({ vin_coerced => '3D7KS28C26G18OO4I  ' }) };
	ok ( !$@ && $vehc, "Valid VIN $@" );
}
