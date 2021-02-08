use strict; use warnings;

use Test::Most;
use Test::Pod::Coverage;

all_pod_coverage_ok({
        also_private => [ qr/BUILD|BUILDARGS/ ],
});

done_testing;