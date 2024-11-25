use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Thread';

use SPVM 'Fn';
use SPVM::Thread;

# Version
{
  is($SPVM::Thread::VERSION, SPVM::Fn->get_version_string('Thread'));
}

ok(SPVM::TestCase::Thread->basic);

ok(SPVM::TestCase::Thread->thread_id);

done_testing;
