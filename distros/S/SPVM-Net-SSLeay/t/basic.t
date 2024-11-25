use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Net::SSLeay';
use SPVM 'TestCase::Net::SSLeay::Util';
use SPVM 'TestCase::Net::SSLeay::SSL_CTX';

use SPVM 'TestCase::Net::SSLeay::Util';

use SPVM 'Net::SSLeay';
use SPVM::Net::SSLeay;
use SPVM 'Fn';

ok(SPVM::TestCase::Net::SSLeay->test);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_alpn_protos_with_protocols);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_alpn_select_cb_with_protocols);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_next_proto_select_cb_with_protocols);

ok(SPVM::TestCase::Net::SSLeay::SSL_CTX->set_next_protos_advertised_cb_with_protocols);

# Version
{
  my $version_string = SPVM::Fn->get_version_string("Net::SSLeay");
  is($SPVM::Net::SSLeay::VERSION, $version_string);
}

done_testing;
