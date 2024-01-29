use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Resource::Utf8proc';

use SPVM 'Resource::Utf8proc';
use SPVM::Resource::Utf8proc;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Resource::Utf8proc->test);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Resource::Utf8proc");
  is($SPVM::Resource::Utf8proc::VERSION, $version_string);
}

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
