use strict;
use warnings;

use Test::More;
use Test::Requires 'Moo';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::Moo;
use Tester;

Tester::run_tests( Tester::Moo->new );

done_testing;
