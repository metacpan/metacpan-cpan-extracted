use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 5;

BEGIN {
	use_ok( 'Padre::Unload', '0.96' );
	use_ok( 'Padre::Task',   '0.96' );
	use_ok( 'App::Nopaste',  '0.35' );
}

######
# let's check our subs/methods.
######

my @subs = qw( new run );

BEGIN {
	use_ok( 'Padre::Plugin::Nopaste::Task', @subs );
}

can_ok( 'Padre::Plugin::Nopaste::Task', @subs );


done_testing();

__END__
