use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'Resource::SocketUtil';
use SPVM::Resource::SocketUtil;

use SPVM 'TestCase::Resource::SocketUtil';

ok(SPVM::TestCase::Resource::SocketUtil->test);

is($SPVM::Resource::SocketUtil::VERSION, SPVM::Fn->get_version_string('Resource::SocketUtil'));

done_testing;
