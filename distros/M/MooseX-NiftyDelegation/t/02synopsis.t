# Example from SYNOPSIS. Minor changes for 5.8-compat.
#

use 5.008;
use strict;
use warnings;

{
	package My::Process;
	use Moose;
	use MooseX::NiftyDelegation -all;
	
	has status => (
		is       => 'rw',
		isa      => 'Str',
		traits   => [ Nifty ],
		required => 1,
		handles  => {
			is_in_progress  => value_is 'in progress',
			is_failed       => value_is 'failed',
			is_complete     => value_like qr/^complete/,
			completion_date => sub { /^completed (.+)$/ and $1 },
		},
	);
}

{
	package main;
	use Test::More;
	
	my $process = My::Process->new(
		status  => 'completed 2012-11-19',
	);
	
	ok( not $process->is_in_progress );
	ok( not $process->is_failed );
	ok(     $process->is_complete );
	
	is( $process->completion_date, '2012-11-19' );
	
	done_testing;
}

