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
my $applicationname = 'clock';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);

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

sub doFPad {
    my ($val, $len) = @_;

    while(length($val) < $len) {
        $val = '0' . $val;
    }

    return $val;
}
