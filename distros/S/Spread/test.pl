#!/usr/bin/perl

# Filename: test.pl
# Author:   Theo Schlossnagle <jesus@cnds.jhu.edu>
# Created:  12th October 1999
# Version:  1.0312
#
# Copyright (c) 1999,2001 Theo Schlossnagle. All rights reserved.
#   This program is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#

use ExtUtils::testlib;
use Spread qw(:SP :MESS :ERROR);

$version = Spread::version();

$| = 1;

$connect = $join = $multicast = $poll = $receive = $leave = $disconnect = 0;
$timeout = undef;
$spreaddaemon = "4803";

$tests = $fails = 0;

while($_ = shift @ARGV) {
  $multicast=1 if(/-m/);
  $receive=1 if(/-r/);
  $join = 1 if(/-j/);
  $poll = 1 if(/-p/);
  $leave = 1 if(/-l/);
  $disconnect = 1 if(/-d/);
  if(/-rt/) {
    $select = shift @ARGV;
    if($select =~ /^-/) {
      unshift(@ARGV,$select);
    } else {
      $timeout = $select;
    }
    $select = 1;
  }
  if(/-c/) {
    $connect = shift @ARGV;
    if($connect =~ /^-/) {
      unshift(@ARGV,$connect);
    } else {
      $spreaddaemon = $connect;
    }
    $connect = 1;
  }
}

print "Spread client library version $version\n";

$args{'spread_name'} = $spreaddaemon;
$args{'private_name'} = "perltest";
$args{'priority'} = 0;
$args{'group_membership'} = 1;

# CONNECT
if($connect) {
print "Trying to connect to spread...\n";
($mbox, $privategroup) = Spread::connect(
	\%args
	);
$tests++;
$fails++ unless defined($mbox);
print "Mailbox is: ".(defined($mbox)?$mbox:"undef")." and ";
print "private_group is ".(defined($privategroup)?$privategroup:"undef")."\n";
print "$sperrno\n" unless defined($mbox);
}

#JOIN
if($join) {
@groups = ('flooder');
print "Attempting to join: ".join(',', @groups).".\n";
@joined = grep (Spread::join($mbox, $_), @groups);
print "Successfully joined: ".scalar(@joined)." of ".scalar(@groups).
  " group(s) [".join(',', @joined)."].\n";
$tests+=scalar(@groups);
$fails+=(scalar(@groups)-scalar(@joined));
}

#MULTICAST
if($multicast) {
$message = "This is a test.";
print "Attempting to multicast ".length($message)." bytes to [@joined[0]].\n";
$tests++;
if(($ret = Spread::multicast($mbox, 
			     SAFE_MESS, @joined[0], 0, $message))>0) {
  print "Successfully multicasted $ret bytes to [@joined[0]]\n";
} else {
  print "Failed multicast to [@joined[0]]: $sperrno\n";
  $fails++;
}
$message =~ s/a/another/;
print "Attempting to multicast ".length($message)." bytes to [".join(',', @joined)."].\n";
$tests++;
if(($ret = Spread::multicast($mbox, 
			     SAFE_MESS, \@joined, 0, $message))>0) {
  print "Successfully multicasted $ret bytes to [".join(',', @joined)."].\n";
} else {
  print "Failed multicast to [".join(',', @joined)."]: $sperrno\n";
  $fails++;
}
}

#POLL
if($poll) {
print "Polling mailbox for messages.\n";
$tests++;
$ans = Spread::poll($mbox);
if(defined($ans)) {
  print "Mailbox contains $ans bytes.\n";
} else {
  print "Poll failed: $sperrno\n";
  $fails++;
}
}

#RECEIVE
if($receive) {
print "Entering receive loop. ".
  (defined($timeout)?"(Timeout = ".$timeout."s)\n":"\n");
$tests++;
$ato=0;
$received=0;
while(($st, $s, $g, $mt, $e, $mess) = (defined($timeout))?Spread::receive($mbox, $timeout):Spread::receive($mbox)) {
 $received++;
 if(!defined($st)) {
   print "Receive error: $Spread::sperrorno\n";
   last;
 }
}
print "Received $received messages.\n";
}

#LEAVE
if($leave) {
print "Attempting to leave: [".join(',', @joined)."].\n";
$tests+=scalar(@joined);
@left = grep (Spread::leave($mbox, $_) ||
	(($lerror{$_} = $sperrno) && 0), @joined);
$fails+=scalar(@joined)-scalar(@left);
print "Successfully left: [".join(',', @left)."].\n" if(scalar(@left));
while(($k, $v) = each %lerror) {
  print "Failed leave for '$k' beacuse of $v\n";
}
}

#DISCONNECT
if($disconnect) {
$tests++;
if(Spread::disconnect($mbox)) {
  print "Successful disconnect\n";
} else {
  print "Unsuccessful disconnect: $sperrno\n";
  $fails++;
}
}
$tests = 1 unless $tests>0;
printf "\n\nTests $tests, passed ".($tests-$fails)."/$tests = %0.2f%%\n\n",
  100.0*($tests-$fails)/$tests;
