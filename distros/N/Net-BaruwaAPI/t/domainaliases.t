#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI domain alias methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;
my $page = 1;

my $data = {
    name => "example.net",
    status => 1,
    domain => 2,
    accept_inbound => 1,
};

my $aliasid = 10;
my $domainid = 1;

set_expected_response('get_domainaliases');

$res = $do->get_domainaliases($domainid);

# ok($res, 'the get_domainaliases response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid", 'the request uri is correct');

$res = $do->get_domainaliases($domainid, $page);

is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid?page=$page", 'the request uri is correct');

set_expected_response('get_domainalias');

$res = $do->get_domainalias($domainid, $aliasid);

# ok($res, 'the get_domainalias response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid/$aliasid", 'the request uri is correct');

set_expected_response('create_domainalias');

$res = $do->create_domainalias($domainid, $data);

# ok($res, 'the create_domainalias response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid", 'the request uri is correct');

set_expected_response('update_domainalias');

$res = $do->update_domainalias($domainid, $aliasid, $data);

# ok($res, 'the update_domainalias response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid/$aliasid", 'the request uri is correct');

set_expected_response('delete_domainalias');

$res = $do->delete_domainalias($domainid, $aliasid, $data);

# ok($res, 'the delete_domainalias response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domainaliases/$domainid/$aliasid", 'the request uri is correct');

done_testing;
