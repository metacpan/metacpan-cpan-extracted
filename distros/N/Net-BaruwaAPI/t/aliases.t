#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI address alias methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $userid = 1;
my $addressid = 1;
my $data = {
    address => 'info@example.com',
    enabled => 1
};

set_expected_response('get_aliases');

$res = $do->get_aliases($addressid);

# ok($res, 'the get_aliases response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/aliasaddresses/$addressid", 'the request uri is correct');

set_expected_response('create_alias');

$res = $do->create_alias($userid, $data);

# ok($res, 'the create_alias response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/aliasaddresses/$userid", 'the request uri is correct');

set_expected_response('update_alias');

$res = $do->update_alias($addressid, $data);

# ok($res, 'the update_alias response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/aliasaddresses/$addressid", 'the request uri is correct');

set_expected_response('delete_alias');

$res = $do->delete_alias($addressid, $data);

# ok($res, 'the delete_alias response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/aliasaddresses/$addressid", 'the request uri is correct');

done_testing;
