use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'MyZlib';

use SPVM 'Fn';
use SPVM 'Resource::Zlib';
use SPVM::Resource::Zlib;

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

my $gz_file = "$FindBin::Bin/minitest.txt.gz";
SPVM::MyZlib->test_gzopen_gzread($gz_file);

ok(1);

is($SPVM::Resource::Zlib::VERSION, SPVM::Fn->get_version_string('Resource::Zlib'));

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
