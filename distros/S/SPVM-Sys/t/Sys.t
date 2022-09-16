use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Sys';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Spec tests
{
  if ($^O eq 'MSWin32') {
    ok(SPVM::Sys->is_D_WIN32);
  }
  else {
    ok(!SPVM::Sys->is_D_WIN32);
  }
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
