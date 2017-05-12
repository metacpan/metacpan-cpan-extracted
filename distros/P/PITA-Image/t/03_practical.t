#!/usr/bin/perl

# Check how PITA::Image responds to various config files


use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 35;
use File::Spec::Functions ':ALL';
use Params::Util ':ALL';
use File::Temp   ();
use File::Remove ();
use PITA::Image  ();

# Get a common workarea to prevent creating a ton of them
my $tempdir = File::Temp::tempdir();
ok( -d $tempdir, 'Got workarea directory'      );
ok( -r $tempdir, 'Readable workarea directory' );
ok( -w $tempdir, 'Writable workarea directory' );
END {
	if ( $tempdir and -d $tempdir ) {
		File::Remove::remove( \1, $tempdir );
	}
}

$PITA::Image::NOSERVER = $PITA::Image::NOSERVER = 1;





#####################################################################
# Testing functions

sub injector_ok {
	my $injector = catdir( 't', 'injectors', shift );
	ok( -d $injector, "Injector $injector exists" );
	$injector;
}





#####################################################################
# Ping test

SCOPE: {
	my $manager = PITA::Image->new(
		injector => injector_ok('13_ping'),
		cleanup  => 1,
	);
	isa_ok( $manager, 'PITA::Image' );
	is( scalar($manager->tasks), 0, 'Got zero task' );
	ok( $manager->run, '->run returns ok' );
}





#####################################################################
# Discovery test

SCOPE: {
	my $manager = PITA::Image->new(
		injector => injector_ok('14_discover'),
		cleanup  => 1,
	);
	$manager->add_platform(
		scheme => 'perl5',
		path   => $^X,
	);
	isa_ok( $manager, 'PITA::Image' );
	is( scalar($manager->tasks),     0, 'Got one task' );
	is( scalar($manager->platforms), 1, 'Got one platform' );
	isa_ok( ($manager->platforms)[0], 'PITA::Image::Platform' );

	# Prepare
	ok( $manager->prepare, '->prepare returns true' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Discover' );

	# Run the tasks
	ok( $manager->run, '->run returns ok' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Discover' );
	isa_ok( ($manager->tasks)[0]->result, 'PITA::XML::Storable' );
	isa_ok( ($manager->tasks)[0]->result, 'PITA::XML::Guest' );

	# Report the results
	ok( $manager->report, '->report returns ok' );
}





#####################################################################
# Test er... test

SCOPE: {
	my $manager = PITA::Image->new(
		injector => injector_ok('03_good'),
		cleanup  => 1,
	);
	$manager->add_platform(
		scheme => 'perl5',
		path   => $^X,
	);
	isa_ok( $manager, 'PITA::Image' );
	is( scalar($manager->tasks),     0, 'Got one task' );
	is( scalar($manager->platforms), 1, 'Got one platform' );
	isa_ok( ($manager->platforms)[0], 'PITA::Image::Platform' );

	# Prepare
	ok( $manager->prepare, '->prepare returns true' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Test' );

	# Run the tests
	ok( $manager->run, '->run returns ok' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Test' );
	isa_ok( ($manager->tasks)[0]->result, 'PITA::XML::Storable' );
	isa_ok( ($manager->tasks)[0]->result, 'PITA::XML::Report' );

	# Report the results
	ok( $manager->report, '->report returns ok' );
}

exit(0);
