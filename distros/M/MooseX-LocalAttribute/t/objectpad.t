use strict;
use warnings;

use Test::More;
use Test::Requires 'Object::Pad';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::ObjectPad;
use Tester;

Tester::run_tests( Tester::ObjectPad->new );

done_testing;
