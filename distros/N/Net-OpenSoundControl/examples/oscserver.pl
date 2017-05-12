#!/usr/bin/perl

use strict;
use warnings;
use Net::OpenSoundControl::Server;

use Data::Dumper qw(Dumper);

sub dumpmsg {
    print "[$_[0]] ", Dumper $_[1];
}

my $server =
  Net::OpenSoundControl::Server->new(Port => 7777, Handler => \&dumpmsg)
  or die "Could not start server: $@\n";

print "[OSC Server] Receiving messages on port 7777\n";

$server->readloop();

