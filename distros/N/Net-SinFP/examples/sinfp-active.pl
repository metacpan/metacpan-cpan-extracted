#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);

my $target = shift || die("You must specify target IP address\n");
my $port   = shift || die("You must specify target open TCP port\n");

use Net::SinFP;
use Net::SinFP::DB;
use Net::Packet::Target;
use Net::Packet::Env qw($Env);

$Env->updateDevInfo($target);

my $db = Net::SinFP::DB->new(db => "$Bin/../bin/sinfp.db");
$db->loadSignatures;

my $sinfp = Net::SinFP->new(
   db       => $db,
   h2Match  => 1,
   doP1     => 1,
   doP2     => 1,
   doP3     => 1,
   target   => Net::Packet::Target->new(
      ip   => $target,
      port => $port,
   ),
);

$sinfp->start;
$sinfp->analyzeResponses;
$sinfp->matchOsfps;

if ($sinfp->resultList) {
   my $buf = '';
   my %os;
   for ($sinfp->resultList) {
      $os{$_->os.':'.$_->osVersion} = $_;
   }
   for (sort keys %os) {
      $buf .= $os{$_}->os.': '.$os{$_}->osVersion.
         ' ('.$os{$_}->matchMask.'/'.$os{$_}->matchType.')';
      $buf .= "\n";
   }
   $buf ? print $buf : print "sinfp error\n";
}
else {
   print "Unknown operating system\n";
}

$sinfp->clean;
