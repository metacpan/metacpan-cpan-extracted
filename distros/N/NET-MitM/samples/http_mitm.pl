#!/usr/bin/perl -w
# ######################################################################
# Copyright (c) 2013 Ben Aveling
# ######################################################################
# This script 'MitMs' a connection between a http browser and server
# It manipulates the messages being passed:
# - the server knows which hostname the browser thinks it is talking to
# - the server doesn't (re)direct the browser to bypass http_MitM
# ######################################################################

use strict;
use NET::MitM;
my $usage = qq{Usage: perl MitM_pm2.pl remote_host remote_port [local_port]\n};
my $remote_host=shift or die $usage;
my $remote_port=shift or die $usage;
my $local_port=shift || $remote_port; 
my $local_host=`hostname`;
chomp $local_host;
sub send($) {my $_ = shift;s/Host: [^:]*(:\d+)?/Host: $remote_host/;return $_}
sub receive($) {my $_ = shift;s/$remote_host:\d+/$local_host:$local_port/g;return $_}
my $MitM = NET::MitM->new($remote_host, $remote_port, $local_port};
$MitM->send_callback(\&send);
$MitM->receive_callback(\&receive);
$MitM->log_file("http_MitM.log");
$MitM->go();
die "Error: http_MitM aborted: $!"; # MitM->go() does not return unless an error is encountered
