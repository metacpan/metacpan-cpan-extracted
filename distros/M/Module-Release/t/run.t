#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1.0 'no_plan';
use Test::Output;

use Cwd;

use lib qw(t/lib);
require 'setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok $class;
	can_ok $class, 'new';
	};

my @subs = qw( run run_error _run_error_set _run_error_reset );

my $release;
subtest 'make objects' => sub {
	$release = $class->new;
	isa_ok $release, $class;
	can_ok $release, @subs;
	};

subtest 'settings' => sub {
	ok ! defined $release->run_error, "run_error not set yet";

	ok $release->_run_error_set, "Set run_error";
	ok $release->run_error, "run_error is set";

	ok ! $release->_run_error_reset, "run_error is reset";
	ok ! $release->run_error, "run_error is not set";
	};

subtest 'no args to run' => sub {
	my $rc = eval { $release->run };
	my $at = $@;
	ok defined $at, "run with no arguments dies";
	like $at, qr/Didn't get a command!/, "Error message with no arguments";
	};

subtest 'undef arg' => sub {
	my $rc = eval { $release->run( undef ) };
	my $at = $@;
	ok defined $at, "run with undef argument dies";
	like $at, qr/Didn't get a command!/, "Error message with undef argument";
	};

subtest 'bad command' => sub {
	local $ENV{PATH} = '';
	my $warnings;
	local $SIG{__WARN__} = sub {
		$warnings = $_[0];
		};

	my $command = "foo";
	ok ! -x $command, "$command is not executable (good)";

	my $message = eval { $release->run( qq|$command| ) };
	my $at = $@;
	ok defined $at, "Bad command dies";

	if( $^O eq 'MSWin32' ) {
		like $warnings, qr/didn't close cleanly/, 'Saw Windows error';
		}
	else {
		like $at, qr/exec of \Q$command\E failed/, "Error message with bad command";
		}
	};

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
