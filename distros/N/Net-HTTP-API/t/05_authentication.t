use strict;
use warnings;
use Test::More;

package test::auth;
use Net::HTTP::API;

net_api_declare fake_auth => (
    api_base_url          => 'http://localhost',
    format                => 'json',
    authentication        => 1,
    authentication_method => 'my_auth',
);

net_api_method user => (
    method => 'GET',
    path   => '/user/',
);

sub my_auth {
    my ($self, $request, $ua, $h) = @_;
    $request->header('Authentication' => 1);
}

package test::auth::simple;
use Net::HTTP::API;

net_api_declare fake_auth => (
    api_base_url          => 'http://localhost',
    format                => 'json',
    authentication        => 1,
);

net_api_method user => (
    method => 'GET',
    path   => '/user/',
);

package main;

ok my $api = test::auth->new, 'object api created';
$api->api_useragent->add_handler(
    request_send => sub {
        my $request = shift;
        is $request->header('Authentication'), 1, 'authentication header is set';
        my $res = HTTP::Response->new(200);
        $res->content('[{"name":"eris"}]');
        $res;
    }
);
ok $api->user, 'method user success';

ok $api =
  test::auth::simple->new(api_username => 'foo', api_password => 'bar'),
  'object api simple created';
$api->api_useragent->add_handler(
    request_send => sub {
        my $request = shift;
        ok $request->header('authorization'), 'authentication header is set';
        my $res = HTTP::Response->new(200);
        $res->content('[{"name":"eris"}]');
        $res;
    }
);
ok $api->user, 'method user success';

done_testing;
