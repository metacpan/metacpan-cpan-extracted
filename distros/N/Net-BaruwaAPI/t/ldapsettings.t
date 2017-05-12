#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI LDAP settings methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;

my $data = {
    basedn => "ou=Users,dc=example,dc=com",
    nameattribute => "uid",
    emailattribute => "mail",
    binddn => "uid=readonly-admin,ou=Users,dc=example,dc=com",
    bindpw => "P4ssW0rd",
    usetls => 1,
    search_scope => "subtree",
    emailsearch_scope => "subtree"
};

my $serverid = 12;
my $domainid = 1;
my $settingsid = 20;

set_expected_response('get_ldapsettings');

$res = $do->get_ldapsettings($domainid, $serverid, $settingsid);

# ok($res, 'the get_ldapsettings response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/ldapsettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

set_expected_response('create_ldapsettings');

$res = $do->create_ldapsettings($domainid, $serverid, $data);

# ok($res, 'the create_ldapsettings response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/ldapsettings/$domainid/$serverid", 'the request uri is correct');

set_expected_response('update_ldapsettings');

$res = $do->update_ldapsettings($domainid, $serverid, $settingsid, $data);

# ok($res, 'the update_ldapsettings response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/ldapsettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

set_expected_response('delete_ldapsettings');

$res = $do->delete_ldapsettings($domainid, $serverid, $settingsid, $data);

# ok($res, 'the delete_ldapsettings response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/ldapsettings/$domainid/$serverid/$settingsid", 'the request uri is correct');

done_testing;
