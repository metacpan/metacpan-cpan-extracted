use strict;
use warnings;

use Test::More;
use Test::Requires 'Mouse';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::Mouse;
use Tester;

Tester::run_tests( Tester::Mouse->new );

done_testing;
