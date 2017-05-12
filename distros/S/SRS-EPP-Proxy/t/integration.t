# Run the mappings tests as fully integrated tests, i.e. use brause to send requests to an SRS EPP Proxy, and on to
#  an SRS.
# Only runs if appropriate environment vars are set, i.e. not usually run as part of 'make test', unless you have
#  brause installed, a proxy configured and running, and the environment vars setup to point to it.
use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use IntegrationTest;

IntegrationTest::run_tests(@ARGV);
