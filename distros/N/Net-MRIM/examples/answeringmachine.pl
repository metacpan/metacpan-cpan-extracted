#!/usr/bin/perl

use strict;
use Net::MRIM;

my $mrim=Net::MRIM->new(0);
$mrim->hello();
if (!$mrim->login("login\@mail.ru","password")) {
	print "LOGIN REJECTED\n";
	exit;
} else {
	print "LOGGED IN\n";
}
while (1) {
	sleep(1);
	my $ret=$mrim->ping();
	if ($ret->is_message()) {
		print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
		if ($ret->get_message() eq "quit") {
			$mrim->send_message($ret->get_from(),"ok, exiting");
			$mrim->disconnect();
			print "Exit on user command\n";
			exit;
		} elsif ($ret->get_message() eq "help") {
			$mrim->send_message($ret->get_from(),"**help** quit: exit - help: this help - ...");
		} # and we could go on with several other commands below
	} elsif ($ret->is_logout_from_server()) {
		print "Exit on server command\n";
		$mrim->disconnect();
		exit;
	}
}
$mrim->disconnect();

