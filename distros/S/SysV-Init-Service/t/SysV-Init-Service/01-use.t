# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('SysV::Init::Service');
}

# Test.
require_ok('SysV::Init::Service');
