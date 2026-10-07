use Test::More;

use strict;
use warnings;
use lib 't/lib';

use SPVM 'TestCase::IO::Socket::SSL::Online';

# Check network connectivity to httpbin.org using Perl's HTTP::Tiny
use HTTP::Tiny;
my $res = HTTP::Tiny->new(timeout => 5)->get("http://httpbin.org/get");
unless ($res->{success}) {
  plan skip_all => "No internet connection or httpbin.org is down (verified by Perl's HTTP::Tiny)";
}

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

# Basic HTTPS GET request
ok(SPVM::TestCase::IO::Socket::SSL::Online->https_httpbin);

# Manual handshake with SSL_startHandshake => 0
ok(SPVM::TestCase::IO::Socket::SSL::Online->https_httpbin_SSL_startHandshake_false);

# CA verification using Mozilla::CA (Memory)
ok(SPVM::TestCase::IO::Socket::SSL::Online->https_httpbin_with_mozilla_ca);

# CA verification using a temporary file (SSL_ca_file)
ok(SPVM::TestCase::IO::Socket::SSL::Online->https_httpbin_with_mozilla_ca_SSL_ca_file);

# CA verification using a directory (SSL_ca_path)
ok(SPVM::TestCase::IO::Socket::SSL::Online->https_httpbin_with_mozilla_ca_SSL_ca_path);

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
