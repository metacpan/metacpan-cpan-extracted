use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::JSON';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# encode
{
  ok(SPVM::TestCase::JSON->encode_null);
  ok(SPVM::TestCase::JSON->encode_flat_hash);
  ok(SPVM::TestCase::JSON->encode_flat_list);
  ok(SPVM::TestCase::JSON->encode_int);
  ok(SPVM::TestCase::JSON->encode_double);
  ok(SPVM::TestCase::JSON->encode_bool);
  ok(SPVM::TestCase::JSON->encode_string);
  ok(SPVM::TestCase::JSON->encode_nested_hash);
}

# decode
{
  ok(SPVM::TestCase::JSON->decode_null);
  ok(SPVM::TestCase::JSON->decode_flat_hash);
  ok(SPVM::TestCase::JSON->decode_flat_list);
  ok(SPVM::TestCase::JSON->decode_double);
  ok(SPVM::TestCase::JSON->decode_bool);
  ok(SPVM::TestCase::JSON->decode_string);
  ok(SPVM::TestCase::JSON->decode_nested_hash);
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
