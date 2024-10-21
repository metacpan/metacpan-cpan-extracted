use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Net::DNS::Native';

use SPVM 'Net::DNS::Native';
use SPVM::Net::DNS::Native;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Net::DNS::Native->new);

ok(SPVM::TestCase::Net::DNS::Native->getaddrinfo);

ok(SPVM::TestCase::Net::DNS::Native->getaddrinfo_go);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Net::DNS::Native");
  is($SPVM::Net::DNS::Native::VERSION, $version_string);
}

$api->set_exception(undef);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
