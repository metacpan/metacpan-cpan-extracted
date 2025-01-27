use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'TestCase::IO::Socket::SSL';

use SPVM 'IO::Socket::SSL';
use SPVM::IO::Socket::SSL;
use SPVM 'Fn';

use Test::SPVM::Sys::Socket::Util;

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

my $port = Test::SPVM::Sys::Socket::Util::get_available_port();

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_basic($port));

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_SSL_key_SSL_cert($port));

ok(SPVM::TestCase::IO::Socket::SSL->client_and_server_no_connect_SSL($port));

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("IO::Socket::SSL");
  is($SPVM::IO::Socket::SSL::VERSION, $version_string);
}

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
