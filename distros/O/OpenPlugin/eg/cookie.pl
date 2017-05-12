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

$OP->cookie->set_outgoing({   name  => 'testcookie',
                              value => 'My Cookie',
                              expires => '+1h',
                         });

# Send the outgoing HTTP header
$OP->httpheader->send_outgoing();

print "<b>The following headers were sent to your browser:</b><br><br>";
$OP->httpheader->send_outgoing();
