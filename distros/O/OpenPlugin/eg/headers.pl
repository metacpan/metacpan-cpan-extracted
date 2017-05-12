#!/usr/bin/perl -wT

use strict;
use OpenPlugin();

# This example is meant to run under mod_perl, using the defaults found in the
# OpenPlugin.conf.  You can easily change that by changing the drivers in the
# config file, and removing $r from this script.
my $config_file = "/usr/local/etc/OpenPlugin.conf";
my $r = shift;

my $OP = OpenPlugin->new( config  => { src    => $config_file },
                          request => { apache => $r });

# Send the outgoing HTTP header
$OP->httpheader->send_outgoing();

# Loop through every header we've received, and print it
my @headers = $OP->httpheader->get_incoming();
print "<b>Headers:</b><br><hr>";
foreach my $header ( @headers ) {
    print "<li>$header: ", $OP->httpheader->get_incoming( $header ), "<br>";
}

