use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Net::SSLeay';
use SPVM 'TestCase::Net::SSLeay::Util';

use SPVM 'TestCase::Net::SSLeay::Util';

use SPVM 'Net::SSLeay::Constant';

use Test::SPVM::Sys::Socket::Util;

use SPVM 'Net::SSLeay';
use SPVM::Net::SSLeay;
use SPVM 'Fn';

my $api = SPVM::api();

warn "[Test Output]" . SPVM::Net::SSLeay::Constant->OPENSSL_VERSION_TEXT;

my $start_memory_blocks_count = $api->get_memory_blocks_count;

my $port = Test::SPVM::Sys::Socket::Util::get_available_port();

ok(SPVM::TestCase::Net::SSLeay->accept($port));

ok(SPVM::TestCase::Net::SSLeay->ASN1_ENUMERATED);

ok(SPVM::TestCase::Net::SSLeay->ASN1_INTEGER);

ok(SPVM::TestCase::Net::SSLeay->ASN1_OBJECT);

ok(SPVM::TestCase::Net::SSLeay->ASN1_STRING);

ok(SPVM::TestCase::Net::SSLeay->ASN1_OCTET_STRING);

ok(SPVM::TestCase::Net::SSLeay->ASN1_TIME);

ok(SPVM::TestCase::Net::SSLeay->ASN1_GENERALIZEDTIME);

ok(SPVM::TestCase::Net::SSLeay->OBJ);

ok(SPVM::TestCase::Net::SSLeay->SSL_METHOD);

ok(SPVM::TestCase::Net::SSLeay->BIO);

ok(SPVM::TestCase::Net::SSLeay->PEM);

ok(SPVM::TestCase::Net::SSLeay->EVP);

ok(SPVM::TestCase::Net::SSLeay->OPENSSL_INIT);

ok(SPVM::TestCase::Net::SSLeay->PKCS12);

ok(SPVM::TestCase::Net::SSLeay->X509_VERIFY_PARAM);

ok(SPVM::TestCase::Net::SSLeay->X509_NAME);

ok(SPVM::TestCase::Net::SSLeay->X509_CRL);

ok(SPVM::TestCase::Net::SSLeay->X509_EXTENSION);

ok(SPVM::TestCase::Net::SSLeay->X509);

ok(SPVM::TestCase::Net::SSLeay->X509_STORE);

$api->set_exception(undef);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

# Version
{
  my $version_string = SPVM::Fn->get_version_string("Net::SSLeay");
  is($SPVM::Net::SSLeay::VERSION, $version_string);
}

done_testing;
