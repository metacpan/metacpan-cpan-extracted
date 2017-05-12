#!/usr/local/bin/perl


	package OtherPackage;
	our $our_scalar=13;

	package MyPackage;


use Test::More tests => 3;
BEGIN { use_ok('Symbol::Table') };

	my $st = Symbol::Table->New('SCALAR', 'main::OtherPackage');

	# using a reference to a CONSTANT.
	$st->{our_scalar}=\42;

	my $read = $OtherPackage::our_scalar;

	is($read,'42',"confirm read value was overridden and can be read");
	
	###########################################################
	# assignment causes error:
	# "Modification of a read-only value attempted"
	###########################################################
	eval{
	$OtherPackage::our_scalar = 3;
	};

	my $err = $@;
	chomp($err);
	$err=~s{ at .*$}{}; # delete "at filename line ###" piece

	my $exp_err = 'Modification of a read-only value attempted';

	is($err,$exp_err, 
		"attempting to change read-only scalar gives an error");
