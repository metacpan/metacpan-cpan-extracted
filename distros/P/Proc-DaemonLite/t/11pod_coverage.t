# $Id: 11pod_coverage.t 533 2006-05-29 17:26:34Z nicolaw $

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage" if $@;
all_pod_coverage_ok({
		also_private => [ qr/^[A-Z_]+$/ ],
	}); #Ignore all caps

1;

