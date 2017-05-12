use strict;
use warnings;
use Test::More;
use Net::APNs::Extended::Base;

my $apns = Net::APNs::Extended::Base->new(cert => 'xxx');

for my $method (qw{
    host_production
    host_sandbox
    is_sandbox
    port
    password
    cert_file
    cert
    cert_type
    key_file
    key
    key_type
    read_timeout
    write_timeout
    json
}) {
    ok $apns->$method(1);
    is $apns->$method, 1;
}

done_testing;
