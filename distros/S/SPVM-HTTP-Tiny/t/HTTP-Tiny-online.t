use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::HTTP::Tiny';

ok(SPVM::TestCase::HTTP::Tiny->test);

ok(SPVM::TestCase::HTTP::Tiny->go);

done_testing;
