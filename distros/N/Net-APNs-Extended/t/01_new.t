use strict;
use warnings;
use Test::More;
use Net::APNs::Extended;

subtest 'basic' => sub {
    my $apns = Net::APNs::Extended->new(
        cert_file => 'xxx.cert',
        key_file  => 'yyy.key',
    );
    isa_ok $apns, 'Net::APNs::Extended';
    is $apns->is_sandbox, 0;
    is $apns->host_production, 'gateway.push.apple.com';
    is $apns->host_sandbox, 'gateway.sandbox.push.apple.com';
    is $apns->port, 2195;
    is $apns->max_payload_size, 256;
    is $apns->command, 1;
    is $apns->password, undef;
    is $apns->cert_file, 'xxx.cert';
    is $apns->key_file, 'yyy.key';
    is $apns->cert, undef;
    is $apns->key, undef;
    is $apns->read_timeout, 3;
    is $apns->cert_type, Net::SSLeay::FILETYPE_PEM;
    is $apns->key_type, Net::SSLeay::FILETYPE_PEM;
    isa_ok $apns->json, 'JSON::XS';
};

done_testing;
