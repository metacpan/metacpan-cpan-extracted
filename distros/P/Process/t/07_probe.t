#!/usr/bin/perl

# Tests for Process::Probe

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use File::Spec::Functions ':ALL';
use Process::Probe;

sub object {
	my $probe = Process::Probe->new( qw{
		Process
		t::lib::MyDelegatableProcess
		My::Class::Does::Not::Exist
	} );
	isa_ok( $probe, 'Process::Probe'        );
	isa_ok( $probe, 'Process::Delegatable'  );
	isa_ok( $probe, 'Process::Serializable' );
	isa_ok( $probe, 'Process'               );

	return $probe;
}





#####################################################################
# Test Process::Backgroundable

# Run inside our process
SCOPE: {
	my $probe = object();
	is_deeply( [ $probe->available ], [ ],   '->available ok'   );
	is_deeply( [ $probe->unavailable ], [ ], '->unavailable ok' );
	is_deeply(
		[ $probe->unknown ],
		[ qw{
			My::Class::Does::Not::Exist
			Process
			t::lib::MyDelegatableProcess
		} ],
		'->unknown ok',
	);
	$probe->run;
	is_deeply( [ $probe->available ], [ qw{
		Process
		t::lib::MyDelegatableProcess
	} ],   '->available ok'   );
	is_deeply( [ $probe->unavailable ], [ qw{
		My::Class::Does::Not::Exist
	} ], '->unavailable ok' );
	is_deeply( [ $probe->unknown ], [ ], '->unknown ok' );
}

# Run in a delegated process
SCOPE: {
	my $probe = object();
	SCOPE: {
		local @Process::Delegatable::PERLCMD = (
			@Process::Delegatable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
		);
		$probe->delegate;
	}
	is_deeply( [ $probe->available ], [ qw{
		Process
		t::lib::MyDelegatableProcess
	} ],   '->available ok'   );
	is_deeply( [ $probe->unavailable ], [ qw{
		My::Class::Does::Not::Exist
	} ], '->unavailable ok' );
	is_deeply( [ $probe->unknown ], [ ], '->unknown ok' );
}
