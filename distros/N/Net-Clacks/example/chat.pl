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
my $applicationname = 'chatclient';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);
#print 'Connected to server. Info given: ', $chat->getServerinfo(), "\n";

my $chatname = 'example::chat';
my $clockname = 'example::notify';

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
            print '>>> ', $msg->{data}, "\n";
        } elsif($msg->{type} eq 'notify' && $msg->{name} eq $clockname) {
            print "*** Another minute has passed ***\n";
        } elsif($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    sleep(0.2);
}

