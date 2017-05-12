#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI domain methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $data = {
    name => "example.net",
    site_url => "http://baruwa.example.net",
    status => 1,
    smtp_callout => "",
    ldap_callout => "",
    virus_checks => 1,
    virus_checks_at_smtp => 1,
    spam_checks => 1,
    spam_actions => 3,
    highspam_actions => 3,
    virus_actions => 3,
    low_score => "0.0",
    high_score => "0.0",
    message_size => 0,
    delivery_mode => 1,
    language => "en",
    timezone => "Africa/Johannesburg",
    report_every => 3,
    organizations => 1,
};

my $domainid = 1;
my $domain_name = 'example.net';

set_expected_response('get_domains');

$res = $do->get_domains();

# ok($res, 'the get_domains response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), '/api/v1/domains', 'the request uri is correct');

set_expected_response('get_domain');

$res = $do->get_domain($domainid);

# ok($res, 'the get_domain response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domains/$domainid", 'the request uri is correct');

$res = $do->get_domain_by_name($domain_name);

# ok($res, 'the get_domain response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domains/byname/$domain_name", 'the request uri is correct');

set_expected_response('create_domain');

$res = $do->create_domain($data);

# ok($res, 'the create_domain response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domains", 'the request uri is correct');

set_expected_response('update_domain');

$res = $do->update_domain($domainid, $data);

# ok($res, 'the update_domain response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domains/$domainid", 'the request uri is correct');

set_expected_response('delete_domain');

$res = $do->delete_domain($domainid);

# ok($res, 'the delete_domain response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/domains/$domainid", 'the request uri is correct');

done_testing;
