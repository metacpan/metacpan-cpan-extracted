#!/usr/local/bin/perl -w
use strict;
use News::Collabra;
my $admin = new News::Collabra('user', 'pass');
my $result = $admin->server_status;
if (!defined $result) {
	die "Couldn't get server status -- you need to start the admin HTTPD server manually (see '_is_server_port_listening()' in documentation.\n";
}
print "Starting server...\n";
$result = $admin->server_start;
print $result;
$result = $admin->server_status;
print $result;
