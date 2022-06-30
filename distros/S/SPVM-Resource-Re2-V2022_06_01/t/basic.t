use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Resource::Re2::V2022_06_01';

ok(SPVM::TestCase::Resource::Re2::V2022_06_01->test);

done_testing;
