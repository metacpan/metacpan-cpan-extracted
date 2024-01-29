use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Time::Seconds';

use SPVM 'Time::Seconds';
use SPVM::Time::Seconds;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

{
  ok(SPVM::TestCase::Time::Seconds->constant_values);
}

{
  ok(SPVM::TestCase::Time::Seconds->add);
}

{
  ok(SPVM::TestCase::Time::Seconds->subtract);
}

{
  ok(SPVM::TestCase::Time::Seconds->unit_methods);
}

{
  ok(SPVM::TestCase::Time::Seconds->clone);
}

{
  ok(SPVM::TestCase::Time::Seconds->pretty);
}

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Time::Seconds");
  is($SPVM::Time::Seconds::VERSION, $version_string);
}

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
