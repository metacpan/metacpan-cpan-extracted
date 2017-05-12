#!/usr/bin/perl

use strict;
use warnings;
use Net::Jabber::Loudmouth;

if (@ARGV < 3) {
	print STDERR "Usage: $0 <server> <username> <password> [<fingerprint>]\n";
	exit 1;
}

my $connection = Net::Jabber::Loudmouth::Connection->new($ARGV[0]);

if (@ARGV > 3 && !Net::Jabber::Loudmouth::SSL->is_supported()) {
	print STDERR "No SSL support!\n";
	exit 2;
}

my $handler = Net::Jabber::Loudmouth::MessageHandler->new(\&handle_message);
$connection->register_message_handler($handler, 'message', 'normal');

my $info = {
	name	=> $ARGV[1],
	passwd	=> $ARGV[2]
};

if (@ARGV > 3) {
	$connection->set_port($Net::Jabber::Loudmouth::DefaultPortSSL);
	my $ssl = Net::Jabber::Loudmouth::SSL->new(\&ssl_cb, $info, $ARGV[3]);
	$connection->set_ssl($ssl);
}

$connection->open(\&connection_open_cb, $info);

my $main_loop = Glib::MainLoop->new();
$main_loop->run();

sub print_finger {
	my ($fpr, $size) = @_;

	for (my $i = 0; $i < $size-1; $i++) {
		my $c;
		{ no warnings;
			$c = substr($fpr, $i, 1); }
		$c &&= ord $c;
		$c ||= 0;
		printf "%02X:", $c;
	}
	my $c;
	{ no warnings;
		$c = substr($fpr, $size-1, 1); }
	$c &&= ord $c;
	$c ||= 0;
	printf "%02X", $c;
}

sub ssl_cb {
	my ($ssl, $status, $ud) = @_;

	print "SSL status: $status\n";
	if ($status eq 'cert-fingerprint-mismatch') {
		my $fpr = $ssl->get_fingerprint();
		print "Certificate fingerprint does not match expected fingerprint!\n";
		print "Remote fingerprint: ";
		print_finger($fpr, 16);
		print "\nExpected fingerprint: ";
		print_finger($ARGV[3], 16);
		print "\n";
	} elsif ($status eq 'generic-error') {
		print "Generic SSL error!\n";
	}

	return 'continue';
}

sub connection_open_cb {
	my ($connection, $result, $info) = @_;

	print "Connected callback!\n";
	$connection->authenticate($info->{name}, $info->{passwd}, "LmTest", \&authenticate_cb);
	print "Sent auth message\n";
}

sub authenticate_cb {
	my ($connection, $result, $ud) = @_;

	print "Auth: $result\n";

	if ($result) {
		my $m = Net::Jabber::Loudmouth::Message->new_with_sub_type("", 'presence', 'available');
		printf ":: %s\n", $m->get_node->to_string();
		$connection->send($m);
	}
}

sub handle_message {
	my ($handler, $connection, $m) = @_;
	printf "Incoming message from %s\n", $m->get_node->get_attribute('from');
	return 'remove-message';
}
