use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 1;

BEGIN {
	use_ok('Padre::Plugin::Nopaste');
}

diag("Info: Testing Padre::Plugin::Nopaste $Padre::Plugin::Nopaste::VERSION");

done_testing();

__END__
