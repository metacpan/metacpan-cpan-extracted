#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI user delivery server methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $data = {
    address => "192.168.1.151",
    protocol => 1,
    port => 25,
    enabled => 1,
    require_tls => 1,
    verification_only => 1,
};

my $serverid = 12;
my $domainid = 1;

set_expected_response('get_user_deliveryservers');

$res = $do->get_user_deliveryservers($domainid);

# ok($res, 'the get_user_deliveryservers response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/userdeliveryservers/$domainid", 'the request uri is correct');

set_expected_response('get_user_deliveryserver');

$res = $do->get_user_deliveryserver($domainid, $serverid);

# ok($res, 'the get_user_deliveryserver response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/userdeliveryservers/$domainid/$serverid", 'the request uri is correct');

set_expected_response('create_user_deliveryserver');

$res = $do->create_user_deliveryserver($domainid, $data);

# ok($res, 'the create_user_deliveryserver response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/userdeliveryservers/$domainid", 'the request uri is correct');

set_expected_response('update_user_deliveryserver');

$res = $do->update_user_deliveryserver($domainid, $serverid, $data);

# ok($res, 'the update_user_deliveryserver response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/userdeliveryservers/$domainid/$serverid", 'the request uri is correct');

set_expected_response('delete_user_deliveryserver');

$res = $do->delete_user_deliveryserver($domainid, $serverid, $data);

# ok($res, 'the delete_user_deliveryserver response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/userdeliveryservers/$domainid/$serverid", 'the request uri is correct');

done_testing;
