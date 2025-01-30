use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'Resource::Libpng';
use SPVM::Resource::Libpng;

use SPVM 'MyLibpng';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

is(SPVM::MyLibpng->test, 1);

is($SPVM::Resource::Libpng::VERSION, SPVM::Fn->get_version_string('Resource::Libpng'));

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
