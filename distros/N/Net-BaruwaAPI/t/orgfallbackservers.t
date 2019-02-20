#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI organization fallback server methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;
my $page = 1;

my $data = {
    address => "192.168.1.151",
    protocol => 1,
    port => 25,
    enabled => 1,
    require_tls => 1,
    verification_only => 1,
};

my $serverid = 12;
my $orgid = 1;

set_expected_response('get_fallbackservers');

$res = $do->get_fallbackservers($orgid);

# ok($res, 'the get_fallbackservers response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/list/$orgid", 'the request uri is correct');

$res = $do->get_fallbackservers($orgid, $page);

is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/list/$orgid?page=$page", 'the request uri is correct');

set_expected_response('get_fallbackserver');

$res = $do->get_fallbackserver($serverid);

# ok($res, 'the get_fallbackserver response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/$serverid", 'the request uri is correct');

set_expected_response('create_fallbackserver');

$res = $do->create_fallbackserver($orgid, $data);

# ok($res, 'the create_fallbackserver response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/$orgid", 'the request uri is correct');

set_expected_response('update_fallbackserver');

$res = $do->update_fallbackserver($serverid, $data);

# ok($res, 'the update_fallbackserver response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/$serverid", 'the request uri is correct');

set_expected_response('delete_fallbackserver');

$res = $do->delete_fallbackserver($serverid, $data);

# ok($res, 'the delete_fallbackserver response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/fallbackservers/$serverid", 'the request uri is correct');

done_testing;
