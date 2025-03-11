use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::File::Temp';

use SPVM 'Fn';
use SPVM::File::Temp;
use SPVM 'File::Temp';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count();

ok(SPVM::TestCase::File::Temp->new);

ok(SPVM::TestCase::File::Temp->newdir);

# Version
{
  is($SPVM::File::Temp::VERSION, SPVM::Fn->get_version_string('File::Temp'));
}

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
