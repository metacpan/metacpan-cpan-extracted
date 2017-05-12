use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 6;

# Check some dependencies used by Padre::Plugin::YAML
BEGIN {
	use_ok('Padre',     '0.96');
	use_ok('Try::Tiny', '0.18');
	SKIP: {
		skip 'YAML as we running *inux', 1 if $OSNAME ne 'Win32';
		use_ok('YAML', '0.84');
	}
	SKIP: {
		skip 'YAML::XS as we running Win32', 1 if $OSNAME eq 'Win32';
		use_ok('YAML::XS', '0.41');
	}
	use_ok('constant', '1.27');
	use_ok('parent',   '0.228');
}

done_testing();

__END__

