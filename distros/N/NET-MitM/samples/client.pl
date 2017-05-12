#!/usr/bin/perl -w
# ######################################################################
# Copyleft 2013 Ben Aveling
# ######################################################################
# This script implements a crude client - server must always respond
# or client will hang forever.
# ######################################################################

use strict;
use NET::MitM;
my $usage = qq{Usage: perl cliet.pl remote_host remote_client\n};
my $remote_host=shift or die $usage;
my $remote_port=shift or die $usage;
my $client=NET::MitM->new_client($remote_host,$remote_port) || die;
while(<>){
  print $client->send_and_receive($_); # Warning - assumes always 1 reponse per message sent - only true for some servers.
}
