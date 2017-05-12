#!/usr/bin/perl -w
# ######################################################################
# Copyleft 2013 Ben Aveling
# ######################################################################
# This script listens on a port, and echos back anything sent to it.
# ######################################################################

use strict;
use NET::MitM;
my $usage = qq{Usage: perl echo_server.pl port_id\n};
my $port1 = shift or die $usage;
sub echoback(@){ return $_[0]; }
my $server = NET::MitM->new_server($port1,\&echoback) || die("failed to create echo server: $!");
$server->go(); # does not return unless an error occurs
die("echo_server aborted: $!");
