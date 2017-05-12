#
# $Id: 03_pod_coverage.t 151 2004-12-26 22:35:29Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok(
    {
        also_private => [ 'constant' ]
    },
'all modules have POD covered');

#
# EOF
