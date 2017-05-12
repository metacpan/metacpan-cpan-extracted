use strict;
use warnings;
use Test::More;
use Test::Time time => 1476061810; # => 2016-10-10 10:10:10
use Net::Azure::NotificationHubs;

my $hub = Net::Azure::NotificationHubs->new(
    connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=',
    hub_name          => 'myhub',
    apns_expiry       => '2020-10-30T20:10+09:00',
);
isa_ok $hub, 'Net::Azure::NotificationHubs';

subtest 'Test a request for send - apple' => sub {
    my $req = $hub->send({aps => {alert => "Hello World!"}}, format => 'apple', tags => 'mytag');
    isa_ok $req, 'HTTP::Request';
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    can_ok $req, qw/do/;
    is $req->header('Content-Type'), 'application/atom+xml;charset=utf-8', 'Content-Type header is "application/atom+xml;charset=utf-8"';
    is $req->header('Authorization'), 'SharedAccessSignature sr=https%3a%2f%2fmysvc.servicebus.windows.net%2fmyhub%2fmessages%2f&sig=613gusVD9r98Cx5ZjyPR1GqwgJN62kO%2B5hNltW%2Ff9dw%3D&se=1476065410&skn=mykey', 'Test an Authorization header';
    is $req->header('ServiceBusNotification-Tags'), 'mytag', 'ServiceBusNotification-Tags header is "mytag"';
    is $req->header('ServiceBusNotification-Apns-Expiry'), $hub->apns_expiry, 'ServiceBusNotification-Apns-Expiry header is $hub->apns_expiry';
    is $req->header('ServiceBusNotification-Format'), 'apple', 'ServiceBusNotification-Format header is "apple"';
    is $req->uri->scheme, 'https', 'Request URI Scheme is "https"';
    is $req->uri->host, 'mysvc.servicebus.windows.net', 'Request URI host is "mysvc.servicebus.windows.net"';
    is $req->uri->path, '/myhub/messages/', 'Request URI Path is "/myhub/messages/"';
    is_deeply {$req->uri->query_form}, {api_version => '2015-04'}, 'URI Query parameters is api_version:2015-04';
};

subtest 'Test a request for send - gcm' => sub {
    my $req = $hub->send({data => {message => "Hello World!"}}, format => 'gcm');
    isa_ok $req, 'HTTP::Request';
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    can_ok $req, qw/do/;
    is $req->header('Content-Type'), 'application/atom+xml;charset=utf-8', 'Content-Type header is "application/atom+xml;charset=utf-8"';
    is $req->header('Authorization'), 'SharedAccessSignature sr=https%3a%2f%2fmysvc.servicebus.windows.net%2fmyhub%2fmessages%2f&sig=613gusVD9r98Cx5ZjyPR1GqwgJN62kO%2B5hNltW%2Ff9dw%3D&se=1476065410&skn=mykey', 'Test an Authorization header';
    is $req->header('ServiceBusNotification-Format'), 'gcm', 'ServiceBusNotification-Format header is "gcm"';
    is $req->uri->scheme, 'https', 'Request URI Scheme is "https"';
    is $req->uri->host, 'mysvc.servicebus.windows.net', 'Request URI host is "mysvc.servicebus.windows.net"';
    is $req->uri->path, '/myhub/messages/', 'Request URI Path is "/myhub/messages/"';
    is_deeply {$req->uri->query_form}, {api_version => '2015-04'}, 'URI Query parameters is api_version:2015-04';
};

done_testing;