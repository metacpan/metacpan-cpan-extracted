use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Sys::Time';
use SPVM 'Sys';
use SPVM 'Int';

use SPVM 'TestCase::Sys::Time';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

ok(SPVM::TestCase::Sys::Time->gettimeofday);

ok(SPVM::TestCase::Sys::Time->clock);

ok(SPVM::TestCase::Sys::Time->clock_gettime);

ok(SPVM::TestCase::Sys::Time->clock_getres);

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Time->getitimer(0, undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Time->getitimer);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Time->setitimer(0, undef, undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Time->setitimer);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Time->times(undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Time->times);
}

{
  my $clock_nanosleep_supported;
  
  my $obj_major_version = SPVM::Int->new(0);

  if (SPVM::Sys->defined('__APPLE__')) {
    $clock_nanosleep_supported = 0;
  }
  elsif (SPVM::Sys->defined('__FreeBSD__', $obj_major_version)) {
    my $major_version = $obj_major_version->value;
    if ($major_version >= 13) {
      $clock_nanosleep_supported = 1;
    }
    else {
      $clock_nanosleep_supported = 0;
    }
  }
  else {
    $clock_nanosleep_supported = 1;
  }
  
  if (!$clock_nanosleep_supported) {
    eval { SPVM::Sys::Time->clock_nanosleep(0, 0, undef, undef) };
    like($@, qr/not supported/);
  }
  else {
    ok(SPVM::TestCase::Sys::Time->clock_nanosleep);
  }
}

ok(SPVM::TestCase::Sys::Time->nanosleep);

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
