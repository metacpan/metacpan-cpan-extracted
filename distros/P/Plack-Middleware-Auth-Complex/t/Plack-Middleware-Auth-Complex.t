#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 121;
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
BEGIN { use_ok('Plack::Middleware::Auth::Complex') };

use HTTP::Request::Common;
use MIME::Base64 qw/encode_base64/;
use Plack::Test;

sub app {
	my ($env) = shift;
	[200, [], [$env->{REMOTE_USER} || 'Anon']]
}

my $auth;

sub set_auth {
	my ($user, $pass) = @_;
	$auth = 'Basic ' . encode_base64 "$user:$pass"
}

sub is_http {
	my ($resp, $code, $body, $name) = @_;
	is $resp->code, $code, "$name - code";
	is $resp->content, $body, "$name - body";
}

my $has_scrypt = !!eval 'use Authen::Passphrase::Scrypt; 1';
note "Failed to load Authen::Passphrase::Scrypt: $@" unless $has_scrypt;

my $create_table = 'CREATE TABLE users (id TEXT PRIMARY KEY, passphrase TEXT, email TEXT)';

for my $use_scrypt (qw/0 1/) {
	if ($use_scrypt && !$has_scrypt) {
	  SKIP: {
			skip 'Authen::Passphrase::Scrypt not installed', 60
		}
		next
	}

	my $ac = Plack::Middleware::Auth::Complex->new({
		dbi_connect       => ['dbi:SQLite:dbname=:memory:'],
		post_connect_cb   => sub { shift->{dbh}->do($create_table) },
		register_url      => '/register',
		passwd_url        => '/passwd',
		request_reset_url => '/request-reset',
		reset_url         => '/reset',
		cache_max_age     => 0,
		use_scrypt        => $use_scrypt,
	});

	my $app = $ac->wrap(\&app);
	my @register_args = (username => 'user', password => 'password', confirm_password => 'password', email => 'user@example.org');
	my @passwd_args = (password => 'password', new_password => 'newpassword', confirm_new_password => 'newpassword');
	my @reset_args = (username => 'user', new_password => 'password', confirm_new_password => 'password', token => '???:???');

	test_psgi $app, sub {
		my ($cb) = @_;
		is_http $cb->(GET '/'), 200, 'Anon', 'GET /';
		is_http $cb->(POST '/'), 200, 'Anon', 'POST /';
		is_http $cb->(GET '/register'), 200, 'Anon', 'GET /register';
		set_auth 'user', 'password';
		is_http $cb->(GET '/', Authorization => 'Hello'), 200, 'Anon', 'GET / with invalid Authorization';
		is_http $cb->(GET '/', Authorization => $auth), 200, 'Anon', 'GET / with bad user/pass';
		is_http $cb->(POST '/register'), 400, 'Missing parameter username', 'POST /register with no parameters';
		is_http $cb->(POST '/register', [@register_args, username => '???'] ), 400, 'Invalid username', 'POST /register with bad username';
		is_http $cb->(POST '/register', [@register_args, password => '???'] ), 400, 'The two passwords do not match', 'POST /register with different passwords';
		is_http $cb->(POST '/register', \@register_args), 200, 'Registered successfully', 'POST /register with correct parameters',
		  is_http $cb->(POST '/register', \@register_args), 400, 'Username already in use', 'POST /register with existing user',
		  is_http $cb->(GET '/', Authorization => $auth), 200, 'user', 'GET / with correct user/pass';

		is_http $cb->(POST '/passwd'), 401, 'Authorization required', 'POST /passwd without authorization';
		is_http $cb->(POST '/passwd', Authorization => $auth), 400, 'Missing parameter password', 'POST /passwd with no parameters';
		is_http $cb->(POST '/passwd', [@passwd_args, password => '???'], Authorization => $auth), 400, 'Incorrect password', 'POST /passwd with incorrect old password';
		is_http $cb->(POST '/passwd', [@passwd_args, new_password => '???'], Authorization => $auth), 400, 'The two passwords do not match', 'POST /passwd with different new passwords';
		is_http $cb->(POST '/passwd', \@passwd_args, Authorization => $auth), 200, 'Password changed successfully', 'POST /passwd with correct parameters';
		is_http $cb->(GET '/', Authorization => $auth), 200, 'Anon', 'GET / with bad user/pass';
		set_auth 'user', 'newpassword';
		is_http $cb->(GET '/', Authorization => $auth), 200, 'user', 'GET / with correct user/pass';

		is_http $cb->(POST '/request-reset'), 500, 'Password resets are disabled', 'POST /request-reset with password resets disabled';
		$ac->{mail_from} = 'nobody <nobody@example.org>';
		is_http $cb->(POST '/request-reset'), 400, 'No such user', 'POST /request-reset with no username';
		is_http $cb->(POST '/request-reset', [username => '???']), 400, 'No such user', 'POST /request-reset with inexistent username';
		is_http $cb->(POST '/request-reset', [username => 'user']), 200, 'Email sent', 'POST /request-reset with correct user';

		my ($mail) = Email::Sender::Simple->default_transport->deliveries;
		Email::Sender::Simple->default_transport->clear_deliveries;
		my ($token) = $mail->{email}->get_body =~ /token: (.*)$/m;
		chomp $token;			# Remove final \n
		chop $token;			# Remove final \r
		note "Reset token is $token";

		is_http $cb->(POST '/reset'), 400, 'Missing parameter username', 'POST /reset with no parameters';
		is_http $cb->(POST '/reset', [@reset_args, username => '???']), 400, 'No such user', 'POST /reset with inexistent username';
		is_http $cb->(POST '/reset', [@reset_args, new_password => '???']), 400, 'The two passwords do not match', 'POST /reset with different passwords';
		is_http $cb->(POST '/reset', \@reset_args), 400, 'Bad reset token', 'POST /reset with bad token';
		is_http $cb->(POST '/reset', [@reset_args, token => $ac->make_reset_hmac('user', 0) . ':0']), 400, 'Reset token has expired', 'POST /reset with expired token';
		is_http $cb->(POST '/reset', [@reset_args, token => $token]), 200, 'Password reset successfully', 'POST /reset with correct token';
		is_http $cb->(GET '/', Authorization => $auth), 200, 'Anon', 'GET / with bad user/pass';
		set_auth 'user', 'password';
		is_http $cb->(GET '/', Authorization => $auth), 200, 'user', 'GET / with correct user/pass';
	}
}
