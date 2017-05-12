#!/usr/local/bin/perl

	package OtherPackage;
	our $our_scalar=13;

	package MyPackage;

use Test::More tests => 3;
BEGIN { use_ok('Symbol::Table') };


	my $st = Symbol::Table->New('SCALAR', 'main::OtherPackage');
	my $ref = $st->{our_scalar};
	my $val = $$ref;

	is($val,'13', "confirm we can read old scalar value");


	my $override=42;
	$st->{our_scalar}=\$override;

	my $newval = $OtherPackage::our_scalar;

	is($newval, '42', "confirm we can override var via symbol table object");
