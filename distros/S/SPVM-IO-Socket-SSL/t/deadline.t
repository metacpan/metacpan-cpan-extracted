use Test::More;

use strict;
use warnings;
use lib 't/lib';

use SPVM 'TestCase::IO::Socket::SSL';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

{
  ok(SPVM::TestCase::IO::Socket::SSL->connect_deadline);
  ok(SPVM::TestCase::IO::Socket::SSL->read_deadline);
  ok(SPVM::TestCase::IO::Socket::SSL->write_deadline);
  ok(SPVM::TestCase::IO::Socket::SSL->accept_deadline);
  ok(SPVM::TestCase::IO::Socket::SSL->read_deadline_specific);
  ok(SPVM::TestCase::IO::Socket::SSL->write_deadline_specific);
}

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;

