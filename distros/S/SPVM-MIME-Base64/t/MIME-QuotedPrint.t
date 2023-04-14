use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use SPVM 'TestCase::MIME::QuotedPrint';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

# SPVM::Webkit::MIME
{
  ok(SPVM::TestCase::MIME::QuotedPrint->encode_qp());
  ok(SPVM::TestCase::MIME::QuotedPrint->decode_qp());
}

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
