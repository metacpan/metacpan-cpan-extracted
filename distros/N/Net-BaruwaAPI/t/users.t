#!/usr/bin/env perl
use warnings;
use strict;
# use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI user methods" );

my $do = Test::Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com');
isa_ok($do, 'Net::BaruwaAPI');

my $res;
my $page = 1;

set_expected_response('create_user');

my $data = {
    password1 => 'ng5qhhbiwozcANc3',
    password2 => 'ng5qhhbiwozcANc3',
    account_type => 3,
    low_score => 0.0,
    active => 1,
    timezone => 'Africa/Johannesburg',
    spam_checks => 1,
    high_score => 0.0,
    send_report => 1,
    domains => 9,
    username => 'rowdyrough',
    firstname => 'Rowdy',
    lastname => 'Rough',
    email => 'rowdyrough@example.com',
    block_macros => 1,
};

my $update_data = {
    low_score => 5.5,
    active => 1,
    timezone => 'Africa/Johannesburg',
    spam_checks => 1,
    high_score => 10.2,
    send_report => 1,
    domains => 9,
    username => 'rowdyrough',
    firstname => 'Rowdy',
    lastname => 'Rough',
    email => 'rowdyrough@example.com',
    block_macros => 0,
};

my $update_passwd_data = {
    password1 => 'ng5qhhbiwozcANc3',
    password2 => 'ng5qhhbiwozcANc3',
};

$res = $do->create_user($data);

ok($res, 'the create_user response is defined');
is($res->{username}, 'rowdyrough', 'the username is rowdyrough');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), '/api/v1/users', 'the request uri is correct');

set_expected_response('get_users');
$res = $do->get_users();

# ok($res, 'the get_users response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), '/api/v1/users', 'the request uri is correct');

$res = $do->get_users($page);

is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/users?page=$page", 'the request uri is correct');

set_expected_response('get_user');
my $userid = 1;
$res = $do->get_user($userid);

# ok($res, 'the get_user response is defined');
is(get_last_request_method(), 'GET', 'the request method is correct');
is(get_last_request_path(), "/api/v1/users/$userid", 'the request uri is correct');

set_expected_response('update_user');
$res = $do->update_user($update_data);

# ok($res, 'the update_user response is defined');
is(get_last_request_method(), 'PUT', 'the request method is correct');
is(get_last_request_path(), "/api/v1/users", 'the request uri is correct');

set_expected_response('delete_user');
$res = $do->delete_user($update_data);

# ok($res, 'the delete_user response is defined');
is(get_last_request_method(), 'DELETE', 'the request method is correct');
is(get_last_request_path(), "/api/v1/users", 'the request uri is correct');

set_expected_response('set_user_passwd');
$res = $do->set_user_passwd($userid, $update_passwd_data);

# ok($res, 'the set_user_passwd response is defined');
is(get_last_request_method(), 'POST', 'the request method is correct');
is(get_last_request_path(), "/api/v1/users/chpw/$userid", 'the request uri is correct');

done_testing;
