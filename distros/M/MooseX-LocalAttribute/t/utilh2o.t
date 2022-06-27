use strict;
use warnings;

use Test::More;
use Test::Requires 'Util::H2O';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::UtilH2O;
use Tester;

Tester::run_tests( Tester::UtilH2O->new );

done_testing;
