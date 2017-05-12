#!/usr/bin/perl

use strict;
use warnings;
use Net::Jabber::Loudmouth;

if (@ARGV < 5) {
	print "Usage: $0 <server> <username> <password> <connectserver> <connectport>\n";
	exit 1;
}

my $connection = Net::Jabber::Loudmouth::Connection->new($ARGV[3]);
my $jid = $ARGV[1].'@'.$ARGV[0];
$connection->set_jid($jid);
$connection->set_port($ARGV[4]);

my $handler = Net::Jabber::Loudmouth::MessageHandler->new(\&handle_message);
$connection->register_message_handler($handler, 'message', 'normal');

my $info = {
	name	=> $ARGV[1],
	passwd	=> $ARGV[2]
};

$connection->open(\&connection_open_cb, $info);

print "Returned from the connection->open()\n";

my $main_loop = Glib::MainLoop->new();
$main_loop->run();

sub handle_message {
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
		my $m = Net::Jabber::Loudmouth::Message->new_with_sub_type('', 'presence', 'available');
		printf ":: %s\n", $m->get_node->to_string();
		$connection->send($m);
	}
}
