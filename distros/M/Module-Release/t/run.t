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

my @subs = qw( run run_error _run_error_set _run_error_reset );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create test object
my $release = $class->new;
isa_ok( $release, $class );
can_ok( $release, @subs );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try setting some things
ok( ! defined $release->run_error, "run_error not set yet" );

ok( $release->_run_error_set, "Set run_error" );
ok( $release->run_error, "run_error is set" );

ok( ! $release->_run_error_reset, "run_error is reset" );
ok( ! $release->run_error, "run_error is not set" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Don't pass run a command
{
my $rc = eval { $release->run };
my $at = $@;
ok( defined $at, "run with no arguments dies" );
like( $at, qr/Didn't get a command!/, "Error message with no arguments" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pass run undef
{
my $rc = eval { $release->run( undef ) };
my $at = $@;
ok( defined $at, "run with undef argument dies" );
like( $at, qr/Didn't get a command!/, "Error message with undef argument" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pass it a bad command
{
local $ENV{PATH} = '';
my $command = "foo";
ok( ! -x $command, "$command is not executable (good)" );

my $message = eval { $release->run( qq|$command| ) };
my $at = $@;
ok( defined $at, "Bad command dies" );
like( $at, qr/Could not open command/, "Error message with bad command" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pass it a cammand that exits with 255 (which should be bad)
# This use to die, but now it just warns
{
stderr_like
	{ eval { $release->run( qq|$^X -e "exit 255"| ) } }
	qr/didn't close cleanly/, 
	"Error message with bad close";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pass it perl printing hello
{
my $message = $release->run( qq|$^X -e "print q(Hello)"| );
is( $message, 'Hello', "Got right message from running perl" );
}
