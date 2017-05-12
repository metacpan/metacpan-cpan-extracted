use strict;
use warnings FATAL => 'all';

use lib qw(lib);

if ( !do "t/slauth.conf.PL" ) {
	die "$0: failed to run t/slauth.conf.PL: $!\n";
}

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
