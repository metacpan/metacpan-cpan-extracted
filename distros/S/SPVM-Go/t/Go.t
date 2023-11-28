use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Go';

use SPVM 'Go';
use SPVM::Go;
use SPVM 'Fn';

use Time::HiRes;

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

ok(SPVM::TestCase::Go->go_minimal);

ok(SPVM::TestCase::Go->go_basic);

ok(SPVM::TestCase::Go->go_die);

ok(SPVM::TestCase::Go->go_extra);

# sleep
{
  my $start = Time::HiRes::time;
  
  ok(SPVM::TestCase::Go->sleep);
  
  my $end = Time::HiRes::time;
  
  my $proc_time = $end - $start;
  
  warn("[Test Output]Proc time:$proc_time");
  
  ok($proc_time > 1.5 && $proc_time < 1.52);
}

ok(SPVM::TestCase::Go->thread_exception);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

# Version
{
  my $version_string = SPVM::Fn->get_version_string("Go");
  is($SPVM::Go::VERSION, $version_string);
}

done_testing;
