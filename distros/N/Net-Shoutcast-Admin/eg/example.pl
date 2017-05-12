#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';
use Net::Shoutcast::Admin;

# Simple usage example for Net::Shoutcast::Admin
# $Id: example.pl 315 2008-03-19 00:07:39Z davidp $


my ($host, $port, $password) = @ARGV;

if (!$host || !$port || !$password) {
    die "Usage: $0 hostname port password";
}

my $shoutcast = Net::Shoutcast::Admin->new(
    host => $host,   port => $port,   admin_password => $password,
);

if ($shoutcast->source_connected) {
    my $listeners = $shoutcast->listeners;
    print "Stream is up, with $listeners listeners.\n";
    print "Current song is: " . $shoutcast->currentsong->title . "\n";
    
    for my $listener ( $shoutcast->listeners ) {
        printf "Listener from %s has been listening for %s\n",
            $listener->host, $listener->listen_time;
    }
    
    print "The last songs played are:\n";
    
    for my $song ($shoutcast->song_history) {
        print $song->title . "\n";
    }
    
} else {
    print "No source is currently connected.";
}