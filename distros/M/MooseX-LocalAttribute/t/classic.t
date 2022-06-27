use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::Classic;
use Tester;

Tester::run_tests( Tester::Classic->new );

done_testing;
