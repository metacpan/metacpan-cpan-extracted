#!/usr/bin/perl

# Main tests for Module::Math::Depends

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Module::Math::Depends;
use constant MMD => 'Module::Math::Depends';





#####################################################################
# Basic Testing

SCOPE: {
	my $empty = MMD->new;
	isa_ok( $empty, MMD );
	is( scalar(keys %$empty), 0, '->new makes an empty set' );
}

SCOPE: {
	my $deps = MMD->from_hash( {
		Foo => 1,
		Bar => 0,
		} );
	isa_ok( $deps, MMD );
	is( scalar(keys %$deps), 2, '->from_hash works' );
	isa_ok( $deps->{Foo}, 'version' );
	isa_ok( $deps->{Bar}, 'version' );
	is( $deps->{Foo}->numify, '1.000', 'Foo has ok dep' );
}
