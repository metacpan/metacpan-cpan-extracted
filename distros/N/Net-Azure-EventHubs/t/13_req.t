use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Time time => 1476061810; # => 2016-10-10 10:10:10
use Net::Azure::EventHubs;

my $hub = Net::Azure::EventHubs->new(
    connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
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

subtest 'with path, payload, timeout and api_version' => sub {
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload, timeout => 10, api_version => '2015-01');
    isa_ok $req, 'Net::Azure::EventHubs::Request';
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {timeout => 10, api_version => '2015-01'}, 'query params is timeout: 10, api_version: "2015-01"';
    is $req->header('Content-Type'), 'application/atom+xml;type=entry;charset=utf-8', 'Content-Type is "application/atom+xml;type=entry;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};

subtest 'with path, payload' => sub {
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload);
    isa_ok $req, 'Net::Azure::EventHubs::Request';
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {timeout => $hub->timeout, api_version => $hub->api_version}, 'query params is timeout: 10, api_version: "2015-01"';
    is $req->header('Content-Type'), 'application/atom+xml;type=entry;charset=utf-8', 'Content-Type is "application/atom+xml;type=entry;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};

subtest 'strange instance with path, payload' => sub {
    local $Net::Azure::EventHubs::DEFAULT_API_VERSION = undef;
    local $Net::Azure::EventHubs::DEFAULT_TIMEOUT     = undef;
    $hub = Net::Azure::EventHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
    );
    my $payload = {name => 'oreore', age => 35};
    my $req = $hub->_req('/foo', $payload);
    isa_ok $req, 'Net::Azure::EventHubs::Request';
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST', 'request method is "POST"';
    is $req->uri->path, '/foo', 'request path is "/foo"';
    is_deeply {$req->uri->query_form}, {timeout => '', api_version => ''}, 'query params is timeout: null, api_version: null';
    is $req->header('Content-Type'), 'application/atom+xml;type=entry;charset=utf-8', 'Content-Type is "application/atom+xml;type=entry;charset=utf-8"'; 
    is $req->header('Authorization'), $hub->authorizer->token($req->uri->as_string), 'Authorization header is generated completely';
    is_deeply $hub->serializer->decode($req->content), $payload, 'Content is a payload data that encoded to JSON format';   
};



done_testing;