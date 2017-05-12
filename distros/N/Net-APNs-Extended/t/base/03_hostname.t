use strict;
use warnings;
use Test::More;
use Net::APNs::Extended::Base;

subtest 'is_sandbox: true' => sub {
    my $apns = Net::APNs::Extended::Base->new(
        cert            => 'xxx',
        host_sandbox    => 'sandbox.example.com',
        host_production => 'example.com',
        is_sandbox      => 1,
    );
    is $apns->hostname, $apns->host_sandbox;
};

subtest 'is_sandbox: fasle' => sub {
    my $apns = Net::APNs::Extended::Base->new(
        cert            => 'xxx',
        host_sandbox    => 'sandbox.example.com',
        host_production => 'example.com',
        is_sandbox      => 0,
    );
    is $apns->hostname, $apns->host_production;
};

done_testing;
