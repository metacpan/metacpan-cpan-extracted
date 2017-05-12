#!/usr/bin/perl -w

use strict;

use Net::Elexol::EtherIO24;

my $addr = "192.168.1.80";

Elexol::EtherIO24->debug(3);
my $eio = Elexol::EtherIO24->new(target_addr=>$addr, threaded=>1);

if(!$eio) {
	print STDERR "ERROR: Can't create new EtherIO24 object: ".Elexol::EtherIO24->error."\n";
	exit 1;
}

my $finished = 0;

$SIG{INT} = sub { $finished = 1; };

#$eio->eeprom_fetch;

$eio->send_command("%");
$eio->recv_result("%");

$eio->set_line_dir(1, 0);
$eio->set_line(1, 1);

$eio->set_startup_status;

$eio->reboot;

$eio->close;

