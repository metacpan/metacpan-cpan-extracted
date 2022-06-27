use strict;
use warnings;

use Test::More;
use Test::Requires 'Class::Accessor';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::ClassAccessor;
use Tester;

Tester::run_tests( Tester::ClassAccessor->new );

done_testing;
