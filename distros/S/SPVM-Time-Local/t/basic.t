use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Time::Local';
use SPVM 'Time::Local';
use SPVM::Time::Local;
use SPVM 'Fn';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

# timelocal
{
  ok(SPVM::TestCase::Time::Local->timelocal);
}

# timegm
{
  ok(SPVM::TestCase::Time::Local->timegm);
}

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Time::Local");
  is($SPVM::Time::Local::VERSION, $version_string);
}

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
