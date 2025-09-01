use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Compress::Raw::Zlib';

use SPVM 'Compress::Raw::Zlib';
use SPVM::Compress::Raw::Zlib;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_basic);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_small_buffer);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_WANT_GZIP);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_dictionary);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_options);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_rfc1951);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_fields);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflateReset_and_inflateReset);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflateTune);

ok(SPVM::TestCase::Compress::Raw::Zlib->deflate_and_inflate_LimitOutput);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Compress::Raw::Zlib");
  is($SPVM::Compress::Raw::Zlib::VERSION, $version_string);
}

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
