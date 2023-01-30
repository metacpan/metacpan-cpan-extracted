use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Sys';
use SPVM 'Int';
use SPVM 'Long';
use SPVM 'Double';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# defined
{
  if ($^O eq 'MSWin32') {
    ok(SPVM::Sys->defined('_WIN32'));
  }
  else {
    ok(!SPVM::Sys->defined('_WIN32'));
  }
  
  # value
  if ($^O eq 'linux') {
    {
      my $value = SPVM::Int->new(0);
      SPVM::Sys->defined('__linux', $value);
      ok($value->value);
    }
    {
      my $value = SPVM::Long->new(0);
      SPVM::Sys->defined('__linux', $value);
      ok($value->value);
    }
    {
      my $value = SPVM::Double->new(0);
      SPVM::Sys->defined('__linux', $value);
      ok($value->value);
    }
  }
  
  {
    SPVM::Sys->defined('__GNUC__');
    SPVM::Sys->defined('__clang__');
    SPVM::Sys->defined('__BORLANDC__');
    SPVM::Sys->defined('__INTEL_COMPILER');
    SPVM::Sys->defined('__unix');
    SPVM::Sys->defined('__unix__');
    SPVM::Sys->defined('__linux');
    SPVM::Sys->defined('__linux__');
    SPVM::Sys->defined('__FreeBSD__');
    SPVM::Sys->defined('__NetBSD__');
    SPVM::Sys->defined('__OpenBSD__');
    SPVM::Sys->defined('_WIN32');
    SPVM::Sys->defined('_WIN64');
    SPVM::Sys->defined('_WINDOWS');
    SPVM::Sys->defined('_CONSOLE');
    SPVM::Sys->defined('_WIN32_WINDOWS');
    SPVM::Sys->defined('_WIN32_WINNT');
    SPVM::Sys->defined('__CYGWIN__');
    SPVM::Sys->defined('__CYGWIN32__');
    SPVM::Sys->defined('__MINGW32__');
    SPVM::Sys->defined('__MINGW64__');
    SPVM::Sys->defined('__APPLE__');
    SPVM::Sys->defined('__MACH__');
    SPVM::Sys->defined('__solaris');
  }
}

# get_osname
{
  is(SPVM::Sys->get_osname, $^O);
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
