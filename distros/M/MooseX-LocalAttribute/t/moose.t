use strict;
use warnings;

use Test::More;
use Test::Requires 'Moose';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::Moose;
use Tester;

Tester::run_tests( Tester::Moose->new );

done_testing;
