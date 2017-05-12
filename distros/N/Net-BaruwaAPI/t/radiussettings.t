#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI RADIUS settings methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $data = {
    secret => "P4ssW0rd#",
    timeout => 30
};

my $serverid = 12;
my $domainid = 1;
my $settingsid = 20;

set_expected_response('get_radiussettings');

$res = $do->get_radiussettings($domainid, $serverid, $settingsid);

# ok($res, 'the get_radiussettings response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/radiussettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

set_expected_response('create_radiussettings');

$res = $do->create_radiussettings($domainid, $serverid, $data);

# ok($res, 'the create_radiussettings response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/radiussettings/$domainid/$serverid", 'the request uri is correct');

set_expected_response('update_radiussettings');

$res = $do->update_radiussettings($domainid, $serverid, $settingsid, $data);

# ok($res, 'the update_radiussettings response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/radiussettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

set_expected_response('delete_radiussettings');

$res = $do->delete_radiussettings($domainid, $serverid, $settingsid, $data);

# ok($res, 'the delete_radiussettings response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/radiussettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

done_testing;
