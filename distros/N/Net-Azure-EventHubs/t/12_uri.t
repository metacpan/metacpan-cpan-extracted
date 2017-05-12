use strict;
use warnings;
use Test::More;
use Net::Azure::EventHubs;

my $hub = Net::Azure::EventHubs->new(
    connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
);

subtest 'void params' => sub {
    my $uri = $hub->_uri;
    isa_ok $uri, 'URI::https';
    is $uri->scheme, 'https', 'scheme is "https"';
    is $uri->host, 'mysvc.servicebus.windows.net', 'host is "mysvc.servicebus.windows.net"';
    is $uri->path, '/', 'path is "/"';
    is_deeply {$uri->query_form}, {};
};

subtest 'with path' => sub {
    my $uri = $hub->_uri('/foobar');
    isa_ok $uri, 'URI::https';
    is $uri->scheme, 'https', 'scheme is "https"';
    is $uri->host, 'mysvc.servicebus.windows.net', 'host is "mysvc.servicebus.windows.net"';
    is $uri->path, '/foobar', 'path is "/foobar"';
    is_deeply {$uri->query_form}, {}, 'no query params';
};

subtest 'with params' => sub {
    my $uri = $hub->_uri('/', foo => 'bar', hoge => 123);
    isa_ok $uri, 'URI::https';
    is $uri->scheme, 'https', 'scheme is "https"';
    is $uri->host, 'mysvc.servicebus.windows.net', 'host is "mysvc.servicebus.windows.net"';
    is $uri->path, '/', 'path is "/"';
    is_deeply {$uri->query_form}, {foo => 'bar', hoge => 123}, 'query params is foo: "bar", hoge: 123';
};


done_testing;