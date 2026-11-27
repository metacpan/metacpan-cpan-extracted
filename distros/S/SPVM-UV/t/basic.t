use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();

use SPVM 'TestCase::UV';

use SPVM 'UV';
use SPVM::UV;

my $api = SPVM::api();

# $api->enable_record_object;

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::UV->test);
ok(SPVM::TestCase::UV->poll);
ok(SPVM::TestCase::UV->timer);
ok(SPVM::TestCase::UV->idle);
ok(SPVM::TestCase::UV->async);
ok(SPVM::TestCase::UV->pipe);
ok(SPVM::TestCase::UV->spawn);
ok(SPVM::TestCase::UV->signal);
ok(SPVM::TestCase::UV->tcp);

{
    my $tmp_dir = File::Temp->newdir;
    my $tmp_dir_path = "$tmp_dir";
    # Convert short path to long path on Windows to avoid libuv fs-event assertion failure
    if ($^O eq 'MSWin32') {
      require Win32;
      $tmp_dir_path = Win32::GetLongPathName($tmp_dir_path);
    }
    ok(SPVM::TestCase::UV->fs_event($tmp_dir_path));
  }
  {
    my $tmp_dir = File::Temp->newdir;
    my $tmp_dir_path = "$tmp_dir";
    # Convert short path to long path on Windows to avoid libuv fs-event assertion failure
    if ($^O eq 'MSWin32') {
      require Win32;
      $tmp_dir_path = Win32::GetLongPathName($tmp_dir_path);
    }
    ok(SPVM::TestCase::UV->fs_event_constants($tmp_dir_path));
  }
# Version check
is($SPVM::UV::VERSION, $api->get_version_string("UV"));

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

# warn $api->dump_recorded_objects;

done_testing;
