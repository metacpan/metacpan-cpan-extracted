#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 27;
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
my $applicationname = 'clock';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 49888, $username, $password, $applicationname, $is_caching);

my $clockname = 'example::notify';

my $last = '';

while(1) {
    my $now = getCurrentMinute();
    if($now ne $last) {
        $chat->notify($clockname);
        $chat->ping();
        $last = $now;
    }

    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    sleep(0.2);
}
$chat->disconnect();
exit(0);

sub getCurrentMinute {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$yday, $isdst) = localtime time;
    $year += 1900;
    $mon += 1;

    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    return "$year-$mon-$mday $hour:$min";
}

sub doFPad($val, $len) {
    while(length($val) < $len) {
        $val = '0' . $val;
    }

    return $val;
}
