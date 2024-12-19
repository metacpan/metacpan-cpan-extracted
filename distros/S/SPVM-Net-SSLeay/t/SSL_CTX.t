use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Net::SSLeay::SSL_CTX';

use SPVM 'Net::SSLeay';
use SPVM::Net::SSLeay;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->callback);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->basic);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->new);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_alpn_protos_with_protocols);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_alpn_select_cb_with_protocols);

$api->set_exception(undef);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
