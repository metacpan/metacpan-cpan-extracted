#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI organization methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;
my $page = 1;
my $orgid = 23;

set_expected_response('create_organization');

my $data = {
    name => "My Org",
    domains => [2, 4, 3],
    admins => [3]
};

$res = $do->create_organization($data);

# ok($res, 'the create_organization response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), '/api/v1/organizations', 'the request uri is correct');

set_expected_response('get_organizations');
$res = $do->get_organizations();

# ok($res, 'the get_organizations response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), '/api/v1/organizations', 'the request uri is correct');

$res = $do->get_organizations($page);

is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations?page=$page", 'the request uri is correct');

set_expected_response('get_organization');
$res = $do->get_organization($orgid);

# ok($res, 'the get_organization response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/$orgid", 'the request uri is correct');

set_expected_response('update_organization');
$res = $do->update_organization($orgid, $data);

# ok($res, 'the update_organization response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/$orgid", 'the request uri is correct');

set_expected_response('delete_organization');
$res = $do->delete_organization($orgid);

# ok($res, 'the delete_organization response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/organizations/$orgid", 'the request uri is correct');

done_testing;
