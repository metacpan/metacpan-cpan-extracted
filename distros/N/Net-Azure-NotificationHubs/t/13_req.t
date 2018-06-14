use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::NotificationHubs;

my $hub = Net::Azure::NotificationHubs->new(
    connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=',
    hub_name          => 'myhub',
    apns_expiry       => '2020-10-10T20:20+09:00'
);

subtest 'void params' => sub {
    my $req;
    dies_ok {$req = $hub->_req} qr/path is required/;
    is $req, undef, 'fail to create a request instance';
};

subtest 'with path' => sub {
    my $req;
    dies_ok {$req = $hub->_req('/foo')} qr/payload is required/;
    is $req, undef, 'fail to create a request instance';
};

subtest 'with non_hashref payload' => sub {
    my $req;
    dies_ok {$req = $hub->_req('/foo', 'hogefuga')} qr/payload is not hashref/;
    is $req, undef, 'fail to create a request instance';
};

subtest 'with path, payload and api_version' => sub {
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload, api_version => '2015-01');
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {api_version => '2015-01'}, 'query params is api_version: "2015-01"';
    is $req->header('Content-Type'), 'application/atom+xml;charset=utf-8', 'Content-Type is "application/atom+xml;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};

subtest 'with path, payload' => sub {
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload);
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {api_version => $hub->api_version}, 'query params is api_version: "2015-01"';
    is $req->header('Content-Type'), 'application/atom+xml;charset=utf-8', 'Content-Type is "application/atom+xml;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};

subtest 'strange instance with path, payload' => sub {
    local $Net::Azure::NotificationHubs::DEFAULT_API_VERSION = undef;
    $hub = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=',
        hub_name          => 'myhub',
        apns_expiry       => '2020-10-10T20:20+09:00'
    );
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload);
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {api_version => ''}, 'query params is api_version: null';
    is $req->header('Content-Type'), 'application/atom+xml;charset=utf-8', 'Content-Type is "application/atom+xml;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};

done_testing;