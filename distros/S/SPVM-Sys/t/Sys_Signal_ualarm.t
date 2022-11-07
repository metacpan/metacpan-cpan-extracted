use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use POSIX q(:sys_wait_h);

use SPVM 'Sys::Signal';

use SPVM 'TestCase::Sys::Signal';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Signal->ualarm(0, 0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Signal->ualarm);
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
