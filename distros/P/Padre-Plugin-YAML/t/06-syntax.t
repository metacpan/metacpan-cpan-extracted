use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 3;

BEGIN {
	use_ok( 'Padre::Task::Syntax', '0.96' );
}

######
# let's check our subs/methods.
######

my @subs = qw( _parse_error _parse_error_win32 new run syntax );

BEGIN {
	use_ok( 'Padre::Plugin::YAML::Syntax', @subs );
}

can_ok( 'Padre::Plugin::YAML::Syntax', @subs );


done_testing();

__END__

