#
# description: Test PSGI GET /view partnership interface
#

use Test::More tests => 12;

use strict;
use warnings;

use HTTP::Request::Common qw(GET POST);
use JSON::XS              qw(decode_json);

use File::Basename        qw(dirname);
use lib dirname(__FILE__) . '/lib';
use TestAS2;

my $a = TestAS2::start('A');
is(ref($a), 'Plack::Test::MockHTTP', 'Started Mocked AS2 server');

TestAS2::configure('A', 'A2B', { PORT_A => 4080, PORT_B => 5080 });

my ($resp, $json);

# Get sync partnership
$resp = $a->request(GET(
    'http://127.0.0.1/view/A2B/sync',
));
is($resp->code, 200, 'returned successful response')
  or diag explain $resp;

like($resp->content_type, qr{application/json}, 'returned JSON response');

$json = decode_json($resp->content) or diag explain $resp;

is(ref($json), 'HASH', 'received A response');

like($json->{CertificateDirectory}, qr{/t/A/certificates$}, 'CertificateDirectory is displayed');

my $a2b_sync = {
    'CertificateDirectory'         => $json->{CertificateDirectory},
    'Encryption'                   => '3des',
    'FileHandlerClass'             => 'Net::AS2::PSGI::FileHandler',
    'Mdn'                          => 'sync',
    'MyCertificateFile'            => 'A.cert',
    'MyEncryptionCertificate'      => '...',
    'MyEncryptionKey'              => '...',
    'MyId'                         => 'A',
    'MyKeyFile'                    => 'A.key',
    'MySignatureCertificate'       => '...',
    'MySignatureKey'               => '...',
    'PartnerCertificateFile'       => 'B.cert',
    'PartnerEncryptionCertificate' => '...',
    'PartnerId'                    => 'B',
    'PartnerSignatureCertificate'  => '...',
    'PartnerUrl'                   => 'http://127.0.0.1:5080/receive/B2A/sync',
    'Signature'                    => 'sha1',
    'UserAgentClass'               => 'Net::AS2::HTTP'
};

is_deeply($json, $a2b_sync, 'received A2B sync partnership description');

# Get async
$resp = $a->request(GET(
    'http://127.0.0.1/view/A2B/async',
));
is($resp->code, 200, 'returned successful response')
  or diag explain $resp;

like($resp->content_type, qr{application/json}, 'returned JSON response');

$json = decode_json($resp->content) or diag explain $resp;

is(ref($json), 'HASH', 'received A response');

like($json->{CertificateDirectory}, qr{/t/A/certificates$}, 'CertificateDirectory is displayed');

my $a2b_async = {
    'CertificateDirectory'         => $json->{CertificateDirectory},
    'Encryption'                   => '3des',
    'FileHandlerClass'             => 'Net::AS2::PSGI::FileHandler',
    'Mdn'                          => 'async',
    'MyCertificateFile'            => 'A.cert',
    'MyEncryptionCertificate'      => '...',
    'MyEncryptionKey'              => '...',
    'MyId'                         => 'A',
    'MyKeyFile'                    => 'A.key',
    'MySignatureCertificate'       => '...',
    'MySignatureKey'               => '...',
    'PartnerCertificateFile'       => 'B.cert',
    'PartnerEncryptionCertificate' => '...',
    'PartnerId'                    => 'B',
    'PartnerSignatureCertificate'  => '...',
    'PartnerUrl'                   => 'http://127.0.0.1:5080/receive/B2A/async',
    'MdnAsyncUrl'                  => 'http://127.0.0.1:4080/MDNreceive/A2B/async',
    'Signature'                    => 'sha256',
    'UserAgentClass'               => 'Net::AS2::HTTP'
};

is_deeply($json, $a2b_async, 'received A2B async partnership description');

ok(TestAS2::tear_down('A'), 'removed generated test files for A');
