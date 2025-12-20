#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 33;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);

my $username = 'exampleuser';
my $password = 'unsafepassword';
my $applicationname = 'chatbot';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 49888, $username, $password, $applicationname, $is_caching);
#print 'Connected to server. Info given: ', $chat->getServerinfo(), "\n";

my $chatname = 'example::chat';
my $clockname = 'example::notify';
my $countname = 'chatbot::linecount';

$chat->listen($chatname);
$chat->listen($clockname);
$chat->ping();
$chat->doNetwork();

my $nextping = time + 60;

while(1) {
    my $line = ReadLine -1;

    if(defined($line)) {
        chomp $line;
        if(length($line)) {
            last if(uc $line eq 'QUIT' || uc $line eq 'EXIT');
            $chat->set($chatname, $line);
        }
    }
    if($nextping < time) {
        $chat->ping();
        $nextping = time + 60;
    }
    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'set' && $msg->{name} eq $chatname) {
            # Increment count for every chat message
            $chat->increment($countname);

            # very non-AI answer implementation of "simon says"
            if($msg->{data} =~ /simon/i) {
                $chat->set($chatname, 'RoboSimon says: ' . $msg->{data});
                $chat->increment($countname);
            }
        } elsif($msg->{type} eq 'notify' && $msg->{name} eq $clockname) {
            # Every minute, retrieve our current count, send a chat message and decrease line count accordingly
            my $linecount = $chat->retrieve($countname);
            if(!defined($linecount)) {
                $linecount = 0;
                $chat->store($countname, 0);
            }
            $chat->set($chatname, $linecount . ' new chat messages during the last minute');
            $chat->decrement($countname, $linecount);
        } elsif($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    $chat->doNetwork();
    sleep(1);
}
$chat->disconnect();
exit(0);
