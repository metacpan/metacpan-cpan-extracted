#!/usr/bin/perl

# Tests for Process::Delegatable

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use File::Spec::Functions ':ALL';
use Process::Launcher ();





#####################################################################
# Test Process::Backgroundable

use t::lib::MyDelegatableProcess ();
SCOPE: {
	my $process = t::lib::MyDelegatableProcess->new;
	isa_ok( $process, 't::lib::MyDelegatableProcess' );
	isa_ok( $process, 'Process::Delegatable'         );
	isa_ok( $process, 'Process::Serializable'        );
	isa_ok( $process, 'Process'                      );
	can_ok( $process, 'delegate'                     );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Delegatable::PERLCMD = (
			@Process::Delegatable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
		);
		ok( $process->delegate, '->delegate returns ok' );
	}

	# Should have set the data value
	is( $process->{somedata}, 'foo', '->data set as expected' );
	is( $process->{launcher_version}, $Process::Launcher::VERSION,
		'Used the correct Process::Launcher version' );
	is( $process->{process_version}, $Process::VERSION,
		'Used the correct Process version' );
}




# Repeat for the error case
SCOPE: {
	my $process = t::lib::MyDelegatableProcess->new( pleasedie => 1 );
	isa_ok( $process, 't::lib::MyDelegatableProcess' );
	isa_ok( $process, 'Process::Delegatable'         );
	isa_ok( $process, 'Process::Serializable'        );
	isa_ok( $process, 'Process'                      );
	can_ok( $process, 'delegate'                     );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Delegatable::PERLCMD = (
			@Process::Delegatable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			);
		ok( $process->delegate, '->delegate returns ok' );
	}

	# Should have set the data value
	is( $process->{somedata},  undef, '->data not set' );
	ok(
		$process->{errstr} =~ /You wanted me to die/,
		'Got error message',
	);
}
