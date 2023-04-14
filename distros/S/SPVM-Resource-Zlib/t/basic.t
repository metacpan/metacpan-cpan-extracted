use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'MyZlib';

my $gz_file = "$FindBin::Bin/minitest.txt.gz";
SPVM::MyZlib->test_gzopen_gzread($gz_file);

ok(1);

done_testing;
