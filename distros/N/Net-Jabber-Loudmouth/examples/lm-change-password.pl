#!/usr/bin/perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Net::Jabber::Loudmouth;

sub print_usage {
	print "Usage: $0 <server> <username> <oldpassword> <newpassword> [--ssl] [--host <host>]\n";
	exit 1;
}

print_usage() if @ARGV < 4;

my ($server, $username, $old_pass, $new_pass) = @ARGV;
my ($use_ssl, $host) = (FALSE, undef);

if (@ARGV > 4) {
	for (my $i = 4; $i < @ARGV; $i++) {
		if ($ARGV[$i] eq '-s' || $ARGV[$i] eq '--ssl') {
			$use_ssl = TRUE;
		} elsif ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--host') {
			print_usage() if ++$i >= @ARGV;
			$host = $ARGV[$i];
			print "HOST: $host\n";
		}
	}
}

my $connection = Net::Jabber::Loudmouth::Connection->new($server);

if ($host) {
	my $jid = "$username\@$host";
	printf "Setting jid to %s\n", $jid;
	$connection->set_jid($jid);
}

if ($use_ssl) {
	unless (Net::Jabber::Loudmouth::SSL->is_supported()) {
		print "This loudmouth installation doesn't support SSL\n";
		exit 2;
	}

	my $ssl = Net::Jabber::Loudmouth::SSL->new(\&ssl_func);
	$connection->set_ssl($ssl);
	$connection->set_port($Net::Jabber::Loudmouth::DefaultPortSSL);
}

$connection->open_and_block();
$connection->authenticate_and_block($username, $old_pass, 'Password changer');

my $m = Net::Jabber::Loudmouth::Message->new_with_sub_type('', 'iq', 'set');
my $query = $m->get_node->add_child('query');
$query->set_attributes('xmlns', 'jabber:iq:register');
$query->add_child('username', $username);
$query->add_child('password', $new_pass);

my $reply = $connection->send_with_reply_and_block($m);

if ($reply->get_sub_type() eq 'result') {
	print "Password changed\n";
} else {
	print "Failed to change password\n";
}

$connection->close();

sub ssl_func {
	return 'continue';
}
