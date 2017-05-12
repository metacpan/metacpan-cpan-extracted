#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);

my $dev    = shift || die("You specify network interface to use\n");
my $filter = shift;

use Net::SinFP;
use Net::SinFP::DB;

my $db = Net::SinFP::DB->new(
   db          => "$Bin/../bin/sinfp.db",
   passiveMode => 1,
);
$db->loadSignatures;

my $sinfp = Net::SinFP->new(
   db      => $db,
   passive => 1,
   h2Match => 1,
);
$sinfp->filter($filter) if $filter;

$sinfp->passiveMatchCallback(sub { displayPassiveResult($sinfp) });
$sinfp->start;

$sinfp->clean;
exit(0);

sub displayPassiveResult {
   my $sinfp = shift;
   my $frame = $sinfp->passiveFrame;

   print $frame->l3->src.':'.$frame->l4->src.' > '.
         $frame->l3->dst.':'.$frame->l4->dst;

   $frame->l4->haveFlagAck ? print " [SYN|ACK]\n"
                           : print " [SYN]\n";

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
}
