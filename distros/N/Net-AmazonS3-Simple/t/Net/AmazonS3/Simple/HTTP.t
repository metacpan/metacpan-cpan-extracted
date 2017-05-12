use strict;
use warnings;

use Test::More tests => 4;
use Mock::Quick;
use Test::Exception;

use_ok('Net::AmazonS3::Simple::HTTP');

$ENV{AWS_S3_DEBUG} = 1;

my $mock_response = qclass(
    -with_new  => 1,
    code       => 200,
    message    => 'OK',
    is_success => 1,
    as_string  => "HTTP/1.1 --MOCK-RESPONSE--\n"
);

my $code_request;

my $http = Net::AmazonS3::Simple::HTTP->new(
    http_client => qstrict(
        request => qmeth {
            my ($self, $request) = @_;

            $code_request->($request);

            return $mock_response->package->new(), 
        }
    ),
    signer => qstrict(
        sign => qmeth {
            my ($sign_class, $request, $region, $payload_sha256_hex) = @_;

            $request->header(Authorize => "--MOCK-SIGN-- region:$region");

            isa_ok($request, 'HTTP::Request', 'sign request');
            is($payload_sha256_hex, 'UNSIGNED-PAYLOAD', 'payload is unsigned');
        }
    ),
    auto_region => 1,
    region => 'test-region',
    secure => 1,
    host => 'testaws.com',
);

subtest 'post request' => sub {
    $code_request = sub {
        my ($request) = @_;
        is($request->method, 'POST', 'method');
        is($request->uri,    'https://test-bucket.testaws.com/abcdefg?comment=path_comment', 'URI');
    };
    
    
    throws_ok {
        $http->request();
    } qr/parameter required/, 'request without parameter';
    
    $http->request(
        method => 'POST',
        bucket  => 'test-bucket',
        path    => 'abcdefg?comment=path_comment',
    );

    done_testing(5);
};

subtest 'get request' => sub {
    $code_request = sub {
        my ($request) = @_;
        is($request->method, 'GET', 'method');
        is($request->uri,    'https://test-bucket.testaws.com/abcdefg?comment=path_comment', 'URI');
    };
    
    
    throws_ok {
        $http->request();
    } qr/parameter required/, 'request without parameter';
    
    $http->request(
        bucket  => 'test-bucket',
        path    => 'abcdefg?comment=path_comment',
    );

    done_testing(5);
};

subtest 'auto_region' => sub {
    my @code = (400, 200);
    $mock_response->override(
        is_success => 1,
        code => sub {
            shift @code;
        },
        content => q{<?xml version="1.0" encoding="UTF-8"?>
        <Error><Code>AuthorizationHeaderMalformed</Code><Message>The authorization header is malformed; the region 'test-region' is wrong; expecting 'new-region'</Message><Region>new-region</Region><RequestId>D12400E9695CB8FE</RequestId><HostId>wz2+Qu2Q2W+iZ1FpqWvSh3UUhKI9G9rqVAWW6QXdQnfgDOt2NYHDI6TP39hcAUuPIBp5BmBdufs=</HostId></Error>},
        message => 'Bad Request',
    );

    $http->request(
        bucket  => 'test-bucket',
        path    => 'abcdefg?comment=path_comment',
    );

    is($http->region, 'new-region', 'is set new region');

    $mock_response->restore('is_success', 'code', 'content');

    done_testing(9);
};
