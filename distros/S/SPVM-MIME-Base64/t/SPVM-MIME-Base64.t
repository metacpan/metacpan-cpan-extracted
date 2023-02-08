use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use SPVM 'TestCase::MIME::Base64';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# SPVM::Webkit::MIME
{
  ok(SPVM::TestCase::MIME::Base64->encode_base64());
  ok(SPVM::TestCase::MIME::Base64->decode_base64());
  ok(SPVM::TestCase::MIME::Base64->encoded_base64_length());
  ok(SPVM::TestCase::MIME::Base64->decoded_base64_length());
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
