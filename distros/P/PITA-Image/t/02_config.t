#!/usr/bin/perl

# Check how PITA::Image responds to various config files

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 59;
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





#####################################################################
# Testing functions

sub injector_ok {
	my $injector = catdir( 't', 'injectors', shift );
	ok( -d $injector, "Injector $injector exists" );
	$injector;
}

sub fails_with {
	my $error_like = shift;

	# Create the new object
	my $manager = eval {
		my $foo = PITA::Image->new( @_ );
		$foo->prepare if $foo;
		return $foo;
	};
	ok( ! defined $manager, 'PITA::Image was not created' );

	SKIP: {
		skip("PITA::Image creation did not fail", 1) if $manager;
		like( $@, qr/$error_like/, "Error matches expected ( $error_like )" );
	}
}





#####################################################################
# Test various expected failures

fails_with( 'Image \'injector\' was not provided',
	# No params
);

fails_with( 'Image \'injector\' was not provided',
	workarea => $tempdir,
);

fails_with( 'Failed to find image.conf in the injector',
	workarea => $tempdir,
	injector => injector_ok('01_noconfig'),
);

fails_with( 'Config file is incompatible with PITA::Image',
	workarea => $tempdir,
	injector => injector_ok('02_emptyconfig'),
);

fails_with( 'Config file is incompatible with PITA::Image',
	workarea => $tempdir,
	injector => injector_ok('04_badclass'),
);

fails_with( 'Config file is incompatible with this version of PITA::Image',
	workarea => $tempdir,
	injector => injector_ok('05_badversion'),
);

fails_with( 'Injector lib directory does not exist',
	workarea => $tempdir,
	injector => injector_ok('06_badperl5lib'),
);

fails_with( "Missing 'server_uri' param in image.conf",
	workarea => $tempdir,
	injector => injector_ok('07_noserver'),
);

fails_with( "The 'server_uri' is not a HTTP",
	workarea => $tempdir,
	injector => injector_ok('08_badserver'),
);

fails_with( "Failed to contact SupportServer",
	workarea => $tempdir,
	injector => injector_ok('09_missingserver'),
);

# Below this point use ignore the support server.
# Convert this to full mock-based testing later
$PITA::Image::NOSERVER = $PITA::Image::NOSERVER = 1;

fails_with( qr/Missing \[task\] section in image.conf/,
	workarea => $tempdir,
	injector => injector_ok('10_notask'),
);

### TO BE COMPLETED





#####################################################################
# Test a basic good injector

SCOPE: {
	my $manager = PITA::Image->new(
		workarea => $tempdir,
		injector => injector_ok('03_good'),
		);
	isa_ok( $manager, 'PITA::Image' );
	is( $manager->cleanup, '', '->cleanup is false' );
	is( scalar($manager->tasks), 0, 'Got one task' );

	# Prepare
	ok( $manager->prepare, '->prepare returns true' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Test' );

	# Run the tests
	ok( $manager->run, '->run returns ok' );
	is( scalar($manager->tasks), 1, 'Got one task' );
	isa_ok( ($manager->tasks)[0], 'PITA::Image::Test' );
	isa_ok( ($manager->tasks)[0]->report,  'PITA::XML::Report'  );
	isa_ok( ($manager->tasks)[0]->install, 'PITA::XML::Install' );
	is( scalar(($manager->tasks)[0]->install->commands), 3,
		'Created all three commands as expected' );

	# Dry-run report the results
	my $request = $manager->report_task_request( ($manager->tasks)[0] );
	is( ref($request), 'ARRAY', 'Got ARRAY reference for request' );
	is( $request->[0], 'PUT', '->method is PUT' );
	is( $request->[1], 'http://10.0.2.2/0444B0FE-859C-101A-9C08-D1513C8EECE9', '->uri is http://10.0.2.2/0444B0FE-859C-101A-9C08-D1513C8EECE9' );
	ok( $request->[2]->{content} =~ /^\<\?xml/, 'Generated XML' );
	ok( length($request->[2]->{content}) > 20000, 'Looks long enough' );
	ok( $manager->report, '->report returns ok' );
}

# The workarea directory should NOT be deleted
ok( -d $tempdir, '->workarea dir is not deleted' );

SCOPE: {
	my $manager = PITA::Image->new(
		workarea => $tempdir,
		injector => injector_ok('03_good'),
		cleanup  => 1,
		);
	isa_ok( $manager, 'PITA::Image' );
	is( $manager->cleanup, 1, '->cleanup is true' );
}

# This time, it should be deleted
sleep 1;
ok( ! -d $tempdir, '->workarea is correctly deleted' );
