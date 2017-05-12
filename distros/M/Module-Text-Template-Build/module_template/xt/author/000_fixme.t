
# fixme test

use strict ;
use warnings ;

use Test::More ;
#use Test::UniqueTestNames ;

eval 
{
require Test::Fixme;
Test::Fixme->import();

run_tests
	(
	where    => 'lib',      # where to find files to check
	match    => qr/TODO|FIXME/i,     # what to check for
	#~ skip_all => $ENV{SKIP}  # should all tests be skipped
	) ;
	
};

plan( skip_all => 'Test::Fixme not installed; skipping' ) if $@;