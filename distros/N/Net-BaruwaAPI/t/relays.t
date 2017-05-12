#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI relay methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $relayid = 5;
my $orgid = 23;
my $data = {
    address => "192.168.1.20",
    enabled => 1,
    username => "outboundsmtp",
    password1 => "Str0ngP4ss##",
    password2 => "Str0ngP4ss##",
    description => "Backup-outbound-smtp",
    low_score => 10.0,
    high_score => 15.0,
    spam_actions => 2,
    highspam_actions => 3,
};

set_expected_response('create_relay');

$res = $do->create_relay($orgid, $data);

# ok($res, 'the create_relay response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/relays/$orgid", 'the request uri is correct');

set_expected_response('get_relay');
$res = $do->get_relay($relayid);

# ok($res, 'the get_relay response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/relays/$relayid", 'the request uri is correct');

set_expected_response('update_relay');
$res = $do->update_relay($relayid, $data);

# ok($res, 'the update_relay response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/relays/$relayid", 'the request uri is correct');

set_expected_response('delete_relay');
$res = $do->delete_relay($relayid, $data);

# ok($res, 'the delete_relay response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/relays/$relayid", 'the request uri is correct');

done_testing;
