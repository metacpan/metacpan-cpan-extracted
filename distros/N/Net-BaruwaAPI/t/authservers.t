#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI authentication server methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $data = {
    address => "192.168.1.151",
    protocol => 2,
    port => 993,
    enabled => 1,
    split_address => 1,
    user_map_template => "example_%(user)s"
};

my $serverid = 12;
my $domainid = 1;

set_expected_response('get_authservers');

$res = $do->get_authservers($domainid);

# ok($res, 'the get_authservers response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/authservers/$domainid", 'the request uri is correct');

set_expected_response('get_authserver');

$res = $do->get_authserver($domainid, $serverid);

# ok($res, 'the get_authserver response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/authservers/$domainid/$serverid", 'the request uri is correct');

set_expected_response('create_authserver');

$res = $do->create_authserver($domainid, $data);

# ok($res, 'the create_authserver response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/authservers/$domainid", 'the request uri is correct');

set_expected_response('update_authserver');

$res = $do->update_authserver($domainid, $serverid, $data);

# ok($res, 'the update_authserver response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/authservers/$domainid/$serverid", 'the request uri is correct');

set_expected_response('delete_authserver');

$res = $do->delete_authserver($domainid, $serverid, $data);

# ok($res, 'the delete_authserver response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/authservers/$domainid/$serverid", 'the request uri is correct');

done_testing;
