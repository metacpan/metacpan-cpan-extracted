use strict;
use warnings;

use Test::More;
use Test::Requires 'Mo';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::Mo;
use Tester;

Tester::run_tests( Tester::Mo->new );

done_testing;
