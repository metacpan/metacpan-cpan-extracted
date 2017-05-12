#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use IO::Async::Loop;
use Net::Async::SMTP::Client;
use Email::Simple;
use Net::DNS;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);

binmode STDOUT, ':encoding(UTF-8)';

# You'd want to replace this.
my $domain = 'example.com';
# And this.
my $user = 'user@example.com';
my $email = Email::Simple->create(
	header => [
		From => $user,
		To => $user,
		Subject => 'NaSMTP ẽ test',
	],
	attributes => {
		encoding => "8bitmime",
		charset => "UTF-8",
	},
	body_str => 'some text ë',
);
warn "Will try to send this email:\n" . $email->as_string;

my $loop = IO::Async::Loop->new;
my $smtp = Net::Async::SMTP::Client->new(
	domain => $domain,
	# You can override the auth method, but this should only
	# be necessary for a badly-configured mail server.
	# auth => 'PLAIN',
	# And if you have a cert, you don't need this.
	SSL_verify_mode => SSL_VERIFY_NONE,
);
$loop->add($smtp);

$smtp->connected->then(sub {
	# So the login is a separate step here. It should perhaps be done
	# in the background via instantiation.
	$smtp->login(
		# Also this.
		user => 'someuser',
		# And this.
		pass => 'somepassword',
	)
})->then(sub {
	# and this is the method for sending.
	$smtp->send(
		# And this as well.
		to   => 'person@example.com',
		from => $user,
		data => $email->as_string,
	)
})->get;

