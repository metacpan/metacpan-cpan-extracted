use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 4;

BEGIN {
	use_ok( 'Padre::Unload', '0.96' );
	use_ok( 'Moo',           '1.00' );
}

######
# let's check our subs/methods.
######

my @subs = qw( Codepeek Debian Gist PastebinCom Pastie Shadowcat Snitch Ubuntu servers ssh );

BEGIN {
	use_ok( 'Padre::Plugin::Nopaste::Services', @subs );
}

can_ok( 'Padre::Plugin::Nopaste::Services', @subs );

done_testing();

__END__
