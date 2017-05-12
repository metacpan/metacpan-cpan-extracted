#!/usr/local/bin/perl


	package TopPackage;

	package TopPackage::ModeratePackage;

	package TopPackage::MiddlePackage;

use Test::More tests => 2;
BEGIN { use_ok('Symbol::Table') };

 	my $st_pkg = Symbol::Table->New('PACKAGE', 'TopPackage');

	my %subpackages;

	foreach my $subpkg (keys(%$st_pkg))
		{
		$subpackages{$subpkg}=1;
		}

	my %expected = qw
		(
		ModeratePackage	1
		MiddlePackage	1
		);

	
	is_deeply(\%subpackages,\%expected,"confirm we can see subpackages");

	
