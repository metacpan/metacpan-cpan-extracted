#!/usr/bin/perl

use strict;
use Net::SMS::TMobile::UK;

my $username=shift;
my $password=shift;
my $target=shift;
my $message=shift;

unless ($message) {
	print "\nUsage: $0 <username> <password> <mobilenumber> <message>\n\n";
	exit(1);
}

my $sms = Net::SMS::TMobile::UK->new (username=>$username, password=>$password, debug=>0);
$sms->sendsms(to=>$target, message=>$message, report=>1);

if(my $error = $sms->error) {
	if($error == 5) {
		die("Message or Destination missing\n");
	} elsif ($error == 2) {
		die("Username or password invalid\n");
	} else {
		die("Unexpected fault\n");
	}
}
