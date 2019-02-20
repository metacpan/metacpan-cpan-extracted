#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI organization smarthost methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;
my $page = 1;

my $data = {
    address => "192.168.1.151",
    username => "andrew",
    password => "p4ssw0rd",
    port => 25,
    require_tls => 1,
    enabled => 1,
    description => "outbound-archiver",
};

my $serverid = 12;
my $orgid = 1;

set_expected_response('get_org_smarthosts');

$res = $do->get_org_smarthosts($orgid);

# ok($res, 'the get_org_smarthosts response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid", 'the request uri is correct');

$res = $do->get_org_smarthosts($orgid, $page);

is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid?page=$page", 'the request uri is correct');

set_expected_response('get_org_smarthost');

$res = $do->get_org_smarthost($orgid, $serverid);

# ok($res, 'the get_org_smarthost response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid/$serverid", 'the request uri is correct');

set_expected_response('get_org_smarthost');

$res = $do->get_org_smarthost($orgid, $serverid);

# ok($res, 'the get_org_smarthost response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid/$serverid", 'the request uri is correct');

set_expected_response('create_org_smarthost');

$res = $do->create_org_smarthost($orgid, $data);

# ok($res, 'the create_org_smarthost response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid", 'the request uri is correct');

set_expected_response('update_org_smarthost');

$res = $do->update_org_smarthost($orgid, $serverid, $data);

# ok($res, 'the update_org_smarthost response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid/$serverid", 'the request uri is correct');

set_expected_response('delete_org_smarthost');

$res = $do->delete_org_smarthost($orgid, $serverid, $data);

# ok($res, 'the delete_org_smarthost response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/smarthosts/$orgid/$serverid", 'the request uri is correct');

done_testing;
