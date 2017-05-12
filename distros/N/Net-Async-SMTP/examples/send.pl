#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use IO::Async::Loop;
use Net::Async::SMTP::Client;
use Email::Simple;
use Email::Address;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use Getopt::Long;
use Pod::Usage;

=head1 Usage

 --user     The username for login requests
 --pass     The password to use when logging in
 --domain   Which domain to use for the mail server
 --to       Destination address
 --from     Sender address
 --subject  Subject for the email

User and password are optional, if omitted we will attempt to send
without logging in.

=cut

binmode STDIN, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

GetOptions(
	'user=s'    => \my $user,
	'pass=s'    => \my $pass,
	'domain=s'  => \my $domain,
	'subject=s' => \my $subject,
	'from=s'    => \my $from,
	'to=s'      => \my $to,
	'auth=s'    => \my $auth,
) or pod2usage(2);

use Email::Address;
$from //= $user;
$to //= $from;
$subject //= 'NaSMTP Test Message';
# Extract host from the user if we have a 'user@example.com'-style username
# and no explicit domain
if(defined($user) && !defined($domain)) {
	my ($addr) = Email::Address->parse($user) or die "Could not parse $user";
	$domain = $addr->host;
}

my $body = join '', <STDIN>;

my $email = Email::Simple->create(
	header => [
		From    => $from,
		To      => $to,
		Subject => $subject,
	],
	attributes => {
		encoding => "8bitmime",
		charset  => "UTF-8",
	},
	body_str => $body,
);
warn "Will try to send this email:\n" . $email->as_string;

my $loop = IO::Async::Loop->new;
warn "Will attempt to use $domain as the SMTP server";
my $smtp = Net::Async::SMTP::Client->new(
	domain => $domain,
	# You can override the auth method, but this should only
	# be necessary for a badly-configured mail server.
	($auth ? (auth => $auth) : ()),
	# And if you have a cert, you don't need this.
	SSL_verify_mode => SSL_VERIFY_NONE,
);
$loop->add($smtp);

$smtp->connected->then(sub {
	# So the login is a separate step here. It should perhaps be done
	# in the background via instantiation.
	defined($user) ? (
		$smtp->login(
			user => $user,
			pass => $pass,
		)
	) : (Future->wrap)
})->then(sub {
	# and this is the method for sending.
	$smtp->send(
		# And this as well.
		to   => $to,
		from => $from,
		data => $email->as_string,
	)
})->get;

