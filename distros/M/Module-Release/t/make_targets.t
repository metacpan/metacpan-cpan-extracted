#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;

use Cwd;

my $class = 'Module::Release';
my $file  = ".releaserc";

use_ok( $class );
can_ok( $class, 'new' );

BEGIN {
	use File::Spec;
	my $file = File::Spec->catfile( qw(t lib setup_common.pl) );
	require $file;
	}

my @makefile_pl_targets = qw(
	build_makefile
	);

my @makefile_targets = qw(
	clean
	make
	dist
	distclean
	test
	disttest
	);
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create test object
my $release = $class->new;
isa_ok( $release, $class );
can_ok( $release, @makefile_pl_targets, @makefile_targets );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# API change
{
can_ok( $release, 'dist_test' );

stderr_like 
	{ $release->dist_test }
	qr/deprecated/i,
	'dist_test gives deprecation warning';
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Replace run() with a mock. We don't want to actually do anything.
# Just return whatever is in $output
our $run_output = '';
{
no warnings;
no strict;
*{"${class}::run"} = sub { $run_output };
}

can_ok( $release, 'run' );
is( $release->run, '', "Mock run starts off as empty string" );
is( $release->run, $run_output, "Mock run() returns value of \$run_output" );

$run_output = 'Hello there!';
is( $release->run, $run_output, "Mock run() returns value of \$run_output" );

is( $release->run( qw(a b ) ), $run_output, "Mock run(a,b) returns value of \$run_output" );

$run_output = ''; # run doesn't output anything

$release->turn_quiet_off;
$release->turn_debug_off;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# No Makefile or Makefile.PL present, so skipping
ok( ! -e 'Makefile',    'Makefile is not there (good)'    );
ok( ! -e 'Makefile.PL', 'Makefile.PL is not there (good)' );

foreach my $target ( @makefile_targets, @makefile_pl_targets )
	{
	stdout_like
		{ eval { $release->$target() } }
		qr/no Makefile.*skipping/,
		"Skipping $target with no Makefile"
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# No Makefile, but Makefile.PL present
{
END { unlink 'Makefile.PL' }
open my($fh), ">", "Makefile.PL";
close $fh;
}

foreach my $target ( @makefile_targets )
	{
	next if $target eq 'dist'; # this one recreates it
	ok( ! -e 'Makefile',  'Makefile is not there (good)'    );

	stdout_like
		{ eval { $release->$target() } }
		qr/no Makefile.*skipping/,
		"Skipping $target with no Makefile"
	}
	
foreach my $target ( @makefile_pl_targets )
	{
	ok( -e 'Makefile.PL', 'Makefile.PL is not there' );

	stdout_like
		{ eval { $release->$target() } }
		qr/done/,
		"Target $target completes"
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Makefile and Makefile.PL present, for simple targets
{
END { unlink 'Makefile' }
open my($fh), ">", "Makefile";
close $fh;
}

my %target_needs_more = map { $_, 1 } qw(dist test disttest);

foreach my $target ( @makefile_targets, @makefile_pl_targets )
	{
	next if exists $target_needs_more{$target};
	
	ok( -e 'Makefile',    'Makefile is there'    );
	ok( -e 'Makefile.PL', 'Makefile.PL is not there' );
	
	stdout_like
		{ eval { $release->$target() } }
		qr/done/,
		"Target $target completes"
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test and dist_test needs output from run to see if 
# all tests were successful
foreach my $target ( qw(test disttest ) )
	{
	stdout_like
		{ eval { $release->$target() } }
		qr/Checking make $target.../,
		"Target test runs";
	
	{
	local $run_output = '';
	my $rc = eval { $release->turn_quiet_on; $release->$target(); 1 };
	my $at = $@;
	ok( ! defined $rc, "make test fails" );
	like( $at, qr/Tests failed/i, "make test dies because tests did not pass" );
	$release->turn_quiet_off;
	}
	
	{
	local $run_output = 'All tests successful';
	
	stdout_like
		{ eval { $release->$target() } }
		qr/pass/,
		"All tests pass with right run output";
	}
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# dist needs output from run to see if all tests were successful
# It also needs to see an archive file after it is done

ok( -e 'Makefile',    'Makefile is there'    );
ok( -e 'Makefile.PL', 'Makefile.PL is not there' );

$release->turn_quiet_off;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# First, try it without a local file name (will try to guess)
# no output from run
# should fail when guessing fails
{
$release->local_file( undef );
ok( ! defined $release->local_file, "Local file is not defined (good)" );
	
{
local $run_output = '';
$release->turn_quiet_on;
my $rc = eval {  $release->dist; 1 };
my $at = $@;
ok( ! defined $rc, "make dist dies when local file is missing" );
like( $at, qr/Couldn't guess/i, "dist fails whenit can't guess local name" );
$release->turn_quiet_off;
}
	
is( $release->local_file, undef, "Local file is undef (good)" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Second, try it without a local file name (will try to guess)
# expected output from run
# should fail because guessed file doesn't exist
{
local $run_output = 'gzip foo.tar';

{ # make sure we know where we are
no warnings 'uninitialized';
$release->local_file( undef );
ok( ! defined $release->local_file, "Local file is not defined (good)" );
ok( ! -e $release->local_file, "Local file does not exist (good)" );
}

{
$release->turn_quiet_on;
my $rc = eval {  $release->dist; 1 };
my $at = $@;

is( $release->local_file, 'foo.tar.gz', 'file name has right name' );
is( $release->local_file, $release->remote_file, 'local and remote are the same' );

ok( ! -e $release->local_file, "Local file does not exist (good)" );
ok( ! defined $rc, "make dist dies when missing local file" );

like( $at, qr/ does not exist/i, "dist claims local file does not exist" );
$release->turn_quiet_off;
}
	
is( $release->local_file, 'foo.tar.gz', "Local file guessed from output" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Next, try it with a local file name, but with a file does not exist
# should fail because set file name does not exist
{
$release->local_file('not_there');
ok( defined $release->local_file, "Local file is defined" );
ok( ! -e $release->local_file, "Local file does not exist (good)" );

stdout_like
	{ eval{ $release->dist } }
	qr/Making dist/,
	"Target dist runs";

{
local $run_output = '';
$release->turn_quiet_on;
my $rc = eval {  $release->dist; 1 };
my $at = $@;
ok( ! defined $rc, "make dist fails when local file is missing" );
like( $at, qr/does not exist/i, "make test dies because local file does not exist" );
$release->turn_quiet_off;
}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finally, everything should work
# guess the name, the file is there
{
{
END { unlink 'foo.tar.gz' }
open my($fh), ">", "foo.tar.gz";
close $fh;
}

ok( -e 'foo.tar.gz', 'mock distro foo.tar.gz exists' );

local $run_output = 'gzip foo.tar';

$release->local_file( undef );
ok( ! defined $release->local_file, "Local file is not defined (good)" );
	
stdout_like
	{ eval{ $release->dist } }
	qr/done/,
	"Target dist runs and finishes";
	
is( $release->local_file, 'foo.tar.gz', "Local file guessed from output" );
}
