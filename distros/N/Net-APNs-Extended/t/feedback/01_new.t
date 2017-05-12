use strict;
use warnings;
use Test::More;
use Net::APNs::Extended::Feedback;

subtest 'basic' => sub {
    my $apns = Net::APNs::Extended::Feedback->new(
        cert_file => 'xxx.cert',
        key_file  => 'yyy.key',
    );
    isa_ok $apns, 'Net::APNs::Extended::Feedback';
    is $apns->is_sandbox, 0;
    is $apns->host_production, 'feedback.push.apple.com';
    is $apns->host_sandbox, 'feedback.sandbox.push.apple.com';
    is $apns->port, 2196;
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
