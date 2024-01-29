use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Eg';

use SPVM 'Eg';
use SPVM::Eg;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Eg->test);

ok(SPVM::TestCase::Eg->dom_implementation);

ok(SPVM::TestCase::Eg->node);

ok(SPVM::TestCase::Eg->element);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Eg");
  is($SPVM::Eg::VERSION, $version_string);
}

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
