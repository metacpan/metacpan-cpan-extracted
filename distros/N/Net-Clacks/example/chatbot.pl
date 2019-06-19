#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 6.0;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);
use Data::Dumper;

my $username = 'exampleuser';
my $password = 'unsafepassword';
my $applicationname = 'chatbot';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);
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

