use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::Encode';

use SPVM 'Encode';
use SPVM::Encode;
use SPVM 'Fn';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

{
  ok(SPVM::TestCase::Encode->decode_utf8);
  
  ok(SPVM::TestCase::Encode->encode_utf8);
  
  ok(SPVM::TestCase::Encode->decode_utf16);
  
  ok(SPVM::TestCase::Encode->encode_utf16);
  
  ok(SPVM::TestCase::Encode->decode_utf32);
  
  ok(SPVM::TestCase::Encode->encode_utf32);
  
}

# Version
{
  is($SPVM::Encode::VERSION, SPVM::Fn->get_version_string('Encode'));
}

SPVM::Fn->destroy_runtime_permanent_vars;

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
