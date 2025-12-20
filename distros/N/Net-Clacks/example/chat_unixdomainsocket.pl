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
my $applicationname = 'chatclient';
my $is_caching = 0;

# ***** Pretty much the only difference here is we call newSocket() instead of new() and use a filename
# ***** instead of $host and $port
my $chat = Net::Clacks::Client->newSocket('example.sock', $username, $password, $applicationname, $is_caching);

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

