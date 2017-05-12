#!/usr/bin/perl

# Compile-testing for Process

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
use File::Spec::Functions ':ALL';

BEGIN {
	ok( $] > 5.00503, 'Perl version is 5.00503 or newer' );
	use_ok( 'Process'                     );
	use_ok( 'Process::Infinite'           );
	use_ok( 'Process::Serializable'       );
	use_ok( 'Process::Role::Serializable' );
	use_ok( 'Process::Storable'           );
	use_ok( 'Process::Delegatable'        );
	use_ok( 'Process::Launcher'           );
	use_ok( 'Process::Probe'              );
}

is( $Process::VERSION, $Process::Infinite::VERSION,           '::Process == ::Infinite'           );
is( $Process::VERSION, $Process::Serializable::VERSION,       '::Process == ::Serializable'       );
is( $Process::VERSION, $Process::Role::Serializable::VERSION, '::Process == ::Role::Serializable' );
is( $Process::VERSION, $Process::Storable::VERSION,           '::Process == ::Storable'           );
is( $Process::VERSION, $Process::Launcher::VERSION,           '::Process == ::Launcher'           );
is( $Process::VERSION, $Process::Delegatable::VERSION,        '::Process == ::Delegatable'        );
is( $Process::VERSION, $Process::Probe::VERSION,              '::Process == ::Probe'              );

# Does the launcher export the appropriate things
ok( defined(&run),        'Process::Launcher exports &run'        );
ok( defined(&run3),       'Process::Launcher exports &run3'       );
ok( defined(&serialized), 'Process::Launcher exports &serialized' );

# Include the testing modules
use_ok( 't::lib::MySimpleProcess'      );
use_ok( 't::lib::MyStorableProcess'    );
use_ok( 't::lib::MyDelegatableProcess' );
