#!/usr/bin/perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Net::Jabber::Loudmouth;

if (@ARGV < 3) {
	print "Usage: $0 <server> <username> <password> [--ssl]\n";
	exit 1;
}

my ($server, $username, $password, $ssl) = @ARGV;
$ssl = TRUE if $ssl && ($ssl eq '-s' || $ssl eq '--ssl');

my $connection = Net::Jabber::Loudmouth::Connection->new($server);

if ($ssl) {
	unless (Net::Jabber::Loudmouth::SSL->is_supported()) {
		print "This loudmouth installation doesn't support SSL\n";
		exit 2;
	}

	print "Setting SSL\n";
	my $ssl = Net::Jabber::Loudmouth::SSL->new(\&ssl_func);
	$connection->set_ssl($ssl);
	$connection->set_port($Net::Jabber::Loudmouth::DefaultPortSSL);
}

$connection->open_and_block();

my $m = Net::Jabber::Loudmouth::Message->new_with_sub_type('', 'iq', 'set');
my $query = $m->get_node->add_child('query');
$query->set_attributes('xmlns', 'jabber:iq:register');
$query->add_child('username', $username);
$query->add_child('password', $password);

my $reply = $connection->send_with_reply_and_block($m);

if ($reply->get_sub_type() eq 'result') {
	print "Succeeded in register account '$username\@$server'\n";
} elsif ($reply->get_sub_type() eq 'error') {
	print "Failed to register account '$username\@$server' due to: ";

	my $node = $reply->get_node->find_child('error');
	if ($node) {
		printf "%s\n", $node->get_value();
	} else {
		print "Unknown error\n";
	}
}

$connection->close();

sub ssl_func {
	return 'continue';
}
