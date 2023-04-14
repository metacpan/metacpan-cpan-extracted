use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use MIME::Base64;
use SPVM 'TestCase::MIME::Base64';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

# encode_base64
{
  ok(SPVM::TestCase::MIME::Base64->encode_base64());
  
  {
    my $string = "aaaaaaaaaabbccccccbbdddddd";
    my $eol = "bb";
    is(MIME::Base64->encode_base64($string, $eol), MIME::Base64->encode_base64($string, $eol));
  }
}

# decode_base64
{
  ok(SPVM::TestCase::MIME::Base64->decode_base64());
}

# encoded_base64_length
{
  ok(SPVM::TestCase::MIME::Base64->encoded_base64_length());
}

# decoded_base64_lengt
{
  ok(SPVM::TestCase::MIME::Base64->decoded_base64_length());
}

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
