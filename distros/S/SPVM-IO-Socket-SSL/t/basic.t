use Test::More;

use strict;
use warnings;
use lib 't/lib';

use SPVM 'TestCase::IO::Socket::SSL';

use SPVM 'IO::Socket::SSL';
use SPVM::IO::Socket::SSL;

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_basic);

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_SSL_key_SSL_cert);

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_no_connect_SSL);

# Version check
{
  my $version_string = $api->get_version_string("IO::Socket::SSL");
  is($SPVM::IO::Socket::SSL::VERSION, $version_string);
}

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
