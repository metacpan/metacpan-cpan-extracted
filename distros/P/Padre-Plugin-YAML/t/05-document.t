use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 3;

BEGIN {
	use_ok( 'Padre::Document', '0.96' );
}

######
# let's check our subs/methods.
######

my @subs = qw( task_functions task_outline task_syntax comment_lines_str );

BEGIN {
	use_ok( 'Padre::Plugin::YAML::Document', @subs );
}

can_ok( 'Padre::Plugin::YAML::Document', @subs );

done_testing();

__END__

