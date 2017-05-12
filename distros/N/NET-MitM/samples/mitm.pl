#!/usr/bin/perl -w
# ######################################################################
# Copyright (c) 2013 Ben Aveling
# ######################################################################
# This script 'MitMs' a connection between a client and a server
# ######################################################################

use strict;
use NET::MitM;
my $usage = qq{Usage: perl MitM.pl remote_host remote_port [local_port]\n};
my $remote_host=shift or die $usage;
my $remote_port=shift or die $usage;
my $local_port=shift or die $usage;
my $MitM = NET::MitM->new($remote_host, $remote_port, $local_port);
$MitM->log_file("MitM.log");
$MitM->go();
