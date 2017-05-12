#!/usr/bin/perl

use strict;
use warnings;
use Net::Jabber::Loudmouth;

if (@ARGV < 5) {
	print "Usage: $0 <server> <username> <password> <proxyserver> <proxyport>\n";
	exit 1;
}

my $connection = Net::Jabber::Loudmouth::Connection->new($ARGV[0]);
my $proxy = Net::Jabber::Loudmouth::Proxy->new('http');
$proxy->set_server($ARGV[3]);
$proxy->set_port($ARGV[4]);
$connection->set_proxy($proxy);

my $handler = Net::Jabber::Loudmouth::MessageHandler->new(\&handle_messages);
$connection->register_message_handler($handler, 'message', 'normal');

my $info = {
	name	=> $ARGV[1],
	passwd	=> $ARGV[2]
};

$connection->open(\&connection_open_cb, $info);

my $main_loop = Glib::MainLoop->new();
$main_loop->run();

sub handle_messages {
	my ($handler, $connection, $m) = @_;

	printf "Incoming message from %s\n", $m->get_node->get_attribute('from');
	return 'remove-message';
}

sub connection_open_cb {
	my ($connection, $result, $info) = @_;

	print "Connected callback\n";
	$connection->authenticate($info->{name}, $info->{passwd}, "LmTest", \&authentication_cb, $info);
	print "Sent auth message\n";
}

sub authentication_cb {
	my ($connection, $result) = @_;

	printf "Auth: %d\n", $result;

	if ($result) {
		my $m = Net::Jabber::Loudmouth::Message->new('', 'presence', 'available');
		printf ":: %s\n", $m->get_node->to_string();
		$connection->send($m);
	}
}
