#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 31;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

BEGIN {
    if(contains('--debug', \@ARGV)) {
        print("Development INC activated\n\n");
        unshift @INC, "../lib";
    }
};

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);

my $username = 'rouser';
my $password = 'bar';
my $applicationname = 'permission_denied_test';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 49888, $username, $password, $applicationname, $is_caching);


my $last = '';

$chat->notify("FOO");

my $keepRunning = 1;
while($keepRunning) {
    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            $keepRunning = 0;
        } elsif($msg->{type} eq 'error_message') {
            if($msg->{data} eq 'permission_denied') {
                print "Received the expected 'permission denied' error.\n";
            } else {
                print "Got unexpected error ", $msg->{data}, "!\n";
            }
            $keepRunning = 0;
        } elsif($msg->{type} eq 'serverinfo') {
            print "Connected to server. Serverinfo: ", $msg->{data}, "\n";
        } else {
            print "MSG Received: ", Dumper($msg);
        }
    }
    sleep(0.2);
}
print "Shutting down...\n";
$chat->disconnect();
print "Exiting...\n";
exit(0);

