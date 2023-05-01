use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::JSON';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# encode_json
{
  ok(SPVM::TestCase::JSON->encode_json_null);
  ok(SPVM::TestCase::JSON->encode_json_bool);
  ok(SPVM::TestCase::JSON->encode_json_number);
  ok(SPVM::TestCase::JSON->encode_json_string);
  ok(SPVM::TestCase::JSON->encode_json_list);
  ok(SPVM::TestCase::JSON->encode_json_hash);
  ok(SPVM::TestCase::JSON->encode_json_object);
}

# decode_json
{
  ok(SPVM::TestCase::JSON->decode_json_null);
  ok(SPVM::TestCase::JSON->decode_json_bool);
  ok(SPVM::TestCase::JSON->decode_json_number);
  ok(SPVM::TestCase::JSON->decode_json_string);
  ok(SPVM::TestCase::JSON->decode_json_list);
  ok(SPVM::TestCase::JSON->decode_json_hash);
  ok(SPVM::TestCase::JSON->decode_json_invalid_json_data);
}

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
