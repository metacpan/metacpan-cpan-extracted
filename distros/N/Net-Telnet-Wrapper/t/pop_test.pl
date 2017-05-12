#!/usr/bin/perl

## ----------------------------------------------------------------------------------------------
## pop_test.pl
##
## Script to test the TCP::HTTP device class. A debug file called "dump.log" is created.
##
## $Id: pop_test.pl 35 2007-07-11 13:57:17Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-11 15:57:17 +0200 (Wed, 11 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

use strict;
use warnings;

use Net::Telnet::Wrapper;
use Data::Dumper;

my $device = "mailserver";
my $user = "user";
my $pass = "pass";
#my $passcode = "passcode"; ## only needed if tacacs is used

my $w = Net::Telnet::Wrapper->new('device_class' => 'TCP::POP', -host => "$device", Dump_Log => "dump.log" );

eval {
	print "MODE = ",$w->get_mode(),"\n";
	
	$w->pop_login("$user", "$pass");
	my @count = $w->get_count_messages();
	print "There are $count[0] messages on the server\n";
	
	print "MODE = ",$w->get_mode(),"\n";
};
if ($@)  {
	die $@;
}

print @{$w->GetOutput()};

print "device class = '",$w->get_device_class(),"\n";
print "id = ",$w->get_id(),"\n";
print "test = ",$w->test(),"\n";

