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

my $session = {};

$session->{foo} = "bar";
my $session_id = $OP->session->save( $session );

# Send the outgoing HTTP header
$OP->httpheader->send_outgoing();

my $session_test = $OP->session->fetch( $session_id );
print "Session ID is ($session_id)<br>";
print "Session Values: $session_test->{foo}";

$OP->session->delete( $session_id );
