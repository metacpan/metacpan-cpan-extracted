use lib 't/lib';
use SPVMImpl;
Digest::MD5::is_spvm();

use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Digest::MD5';

ok(SPVM::TestCase::Digest::MD5->test);

done_testing;
