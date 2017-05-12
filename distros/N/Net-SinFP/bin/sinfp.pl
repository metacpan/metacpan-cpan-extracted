#!/usr/bin/perl
#
# $Id: sinfp.pl 1659 2010-12-24 12:24:19Z gomor $
#
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Getopt::Std;
my %opts;
getopts('d:i:I:p:r:t:f:v46m:M:PF:HOVs:k123aA:C', \%opts);

require Net::SinFP;
use Net::SinFP::Consts qw(:matchMask);

die("\n  -- SinFP - $Net::SinFP::VERSION --\n".
    "\n".
    " o Information about signature database updates, and more:\n".
    " o http://lists.gomor.org/mailman/listinfo/sinfp\n".
    "\n".
    "Usage: $0 -i <targetIp> -p <openTcpPort>\n".
    "\n".
    " o Common parameters:\n".
    "   -i <ip>     target IP\n".
    "   -p <port>   target open TCP port (default: 80)\n".
    "   -d <dev>    network device to use\n".
    "   -I <ip>     source IP address to use\n".
    "   -3          run all probes (default)\n".
    "   -2          run only probes P1 and P2 (stealthier)\n".
    "   -1          run only probe P2 (even stealthier)\n".
    "   -v          be verbose\n".
    "   -s <file>   signature file to use\n".
    "   -C          print complete information about target operating system\n".
    "   -O          print only operating system\n".
    "   -V          print only operating system and its version family\n".
    "   -H          use HEURISTIC2 masks to match signatures (advanced users)\n".
    "   -A <mask1,mask2,...>\n".
    "               use a custom list of matching masks (advanced users)\n".
    "\n".
    " o Online mode specific parameters:\n".
    "   -k   keep generated pcap file\n".
    "   -a   do not generate an anonymized pcap file trace\n".
    "\n".
    " o Offline mode specific parameters:\n".
    "   -f <file>   name of pcap file to analyze\n".
    "\n".
    " o IPv6 specific parameters:\n".
    "   -6         use IPv6 fingerprinting, instead of IPv4\n".
    "   -M <mac>   source MAC address to use\n".
    "   -m <mac>   target MAC address to use\n".
    "   -4         if no IPv6 signature matches, try against IPv4 ones\n".
    "\n".
    " o Active mode specific parameters:\n".
    "   -r <N>   number of tries to perform for a probe (default: 3)\n".
    "   -t <N>   timeout before considering a packet to be lost (default: 3)\n".
    "\n".
    " o Passive mode specific parameters:\n".
    "   -P            passive fingerprinting\n".
    "   -F <filter>   pcap filter\n".
    "")
   unless (($opts{i} && !$opts{6})
        || ($opts{i} && $opts{6} && $opts{m})
        || ($opts{f})
        || ($opts{P}));

$opts{p} = 80 unless $opts{p};
if (! $opts{1} && ! $opts{2} && ! $opts{3}) {
   $opts{3} = 1;
}

my $dbFile;
if ($opts{s}) {
   $dbFile = $opts{s};
}
else {
   for ("$Bin/../db/", "$Bin/") {
      $dbFile = $_.'sinfp.db';
      last if -f $dbFile;
   }
}
print "DEBUG: using db: $dbFile\n" if $opts{v};

die("Unable to find $dbFile\n") unless -f $dbFile;

use Net::Packet::Env qw($Env);
require Net::Packet::Target;

$Env->updateDevInfo($opts{i}) unless $opts{6};

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I} && ! $opts{6};
$Env->ip6($opts{I}) if $opts{I} && $opts{6};
$Env->mac($opts{M}) if $opts{M};
$Env->debug(3)      if $opts{v};

require Net::SinFP::DB;
my $db = Net::SinFP::DB->new(
   db          => $dbFile,
   passiveMode => $opts{P} ? 1 : 0,
   ipv6        => $opts{6} ? 1 : 0,
);
$db->loadSignatures;

my $sinfp = Net::SinFP->new(
   db          => $db,
   ipv6        => $opts{6} ? 1 : 0,
   ipv6UseIpv4 => $opts{4} ? 1 : 0,
);
$sinfp->passive ($opts{P} ? 1 : 0);
$sinfp->verbose ($opts{v} ? 1 : 0);
$sinfp->retry   ($opts{r} ? $opts{r} : 3);
$sinfp->wait    ($opts{t} ? $opts{t} : 3);
$sinfp->offline ($opts{f} ? 1 : 0);
$sinfp->h2Match ($opts{H} ? 1 : 0);
$sinfp->keepFile($opts{k} ? 1 : 0);
$sinfp->filter  ($opts{F}) if $opts{F};
$sinfp->file    ($opts{f}) if $opts{f};
if ($opts{3}) {
   $sinfp->doP1(1);
   $sinfp->doP2(1);
   $sinfp->doP3(1);
}
elsif ($opts{2}) {
   $sinfp->doP1(1);
   $sinfp->doP2(1);
   $sinfp->doP3(0);
}
elsif ($opts{1}) {
   $sinfp->doP1(0);
   $sinfp->doP2(1);
   $sinfp->doP3(0);
}

my $target = Net::Packet::Target->new;
$target->ip ($opts{i}) if ! $opts{6};
$target->ip6($opts{i}) if $opts{6};
$target->mac($opts{m}) if $opts{m};
$target->port($opts{p});
$sinfp->target($target);

$sinfp->passiveMatchCallback(sub { displayPassiveResult($sinfp) });

$sinfp->start; # Passive online mode will block here
               # Passive offline mode will exit here

$sinfp->analyzeResponses;
$opts{A} ? $sinfp->matchOsfps([ split(',', $opts{A}) ]) : $sinfp->matchOsfps;

my $nok = displayWarningAboutClosedPort($sinfp);
unless ($nok) {
   displayResults($sinfp);

   createAnonymizedPcapFile($sinfp)
      if (! $opts{a} && ! $opts{f});
}

$sinfp->clean;

$db->close;

exit(0);

sub noReplyForP1 {
   my $sinfp = shift;
   return 1 if ! $sinfp->doP1 || ! $sinfp->pktP1;
   if (($sinfp->pktP1->reply && $sinfp->pktP1->reply->l4->haveFlagRst)
   ||  (! $sinfp->pktP1->reply)) {
      return 1;
   }
   undef;
}

sub noReplyForP2 {
   my $sinfp = shift;
   return 1 if ! $sinfp->doP2 || ! $sinfp->pktP2;
   if (($sinfp->pktP2->reply && $sinfp->pktP2->reply->l4->haveFlagRst)
   ||  (! $sinfp->pktP2->reply)) {
      return 1;
   }
   undef;
}

sub displayWarningAboutClosedPort {
   my $sinfp = shift;
   if (noReplyForP1($sinfp) && noReplyForP2($sinfp)) {
      print "*** [".$sinfp->target->ip.":".$sinfp->target->port."]: ".
            "Cannot fingerprint a closed or filtered port\n";
      return 1;
   }
   undef;
}

sub _displayResultsOnlyOs {
   my $sinfp = shift;

   my $buf;
   my $ipVersion = $sinfp->getIpVersion;
   my %os = map { $_->os => '' } $sinfp->resultList;
   for (keys %os) {
      $buf .= $ipVersion.': '.$_."\n";
   }
   $buf;
}

sub _displayResultsOnlyOsAndVersionFamily {
   my $sinfp = shift;

   my %os;
   $os{$_->os}->{$_->osVersionFamily} = '' for $sinfp->resultList;

   my $buf;
   for (keys %os) {
      $buf .= $sinfp->getIpVersion.': '.$_.' ';
      $buf .= $_.', ' for sort keys %{$os{$_}};
      $buf =~ s/, $//;
      $buf .= "\n";
   }
   $buf;
}

sub _displayResultsAll {
   my $sinfp = shift;

   my $buf;
   for ($sinfp->resultList) {
      $buf .= $_->ipVersion;
      $buf .= '['.$_->idSignature.']' if $opts{v};
      $buf .= ': '.$_->matchMask.'/'.$_->matchType.
         ': '.$_->systemClass.
         ': '.$_->vendor.
         ': '.$_->os.
         ': '.$_->osVersion
      ;
      if ($_->osVersionChildrenList) {
         my $buf2 = '';
         $buf2 .= $_.', ' for $_->osVersionChildrenList;
         $buf2 =~ s/, $//;
         $buf .= " ($buf2)";
      }
      $buf .= "\n";
   }
   $buf;
}

sub _displayResultsShort {
   my $sinfp = shift;

   my $buf;
   my %os;
   for ($sinfp->resultList) {
      $os{$_->os.':'.$_->osVersion} = $_;
   }
   for (sort keys %os) {
      $buf .= $os{$_}->ipVersion;
      $buf .= ': '.$os{$_}->matchMask.'/'.$os{$_}->matchType.
         ': '.$os{$_}->systemClass.
         ': '.$os{$_}->os.
         ': '.$os{$_}->osVersion
      ;
      $buf .= "\n";
   }
   $buf;
}

sub displayResults {
   my $sinfp = shift;

   my $buf = '';
   $buf .= 'P1: '.$sinfp->sigP1AsString."\n" if $sinfp->doP1;
   $buf .= 'P2: '.$sinfp->sigP2AsString."\n" if $sinfp->doP2;
   $buf .= 'P3: '.$sinfp->sigP3AsString."\n" if $sinfp->doP3;

   return print $buf.$sinfp->getIpVersion.": unknown\n" unless $sinfp->found;

   my $s2 = $sinfp->sigP2;
   if ($s2 && length($s2->{O}) <= 9) {
      for ($sinfp->resultList) {
         if ($_->matchMask ne NS_MATCH_MASK_HEURISTIC0) {
            print '*** WARNING: not enough TCP options for P2 reply, result '.
                  'may be false'."\n";
            last;
         }
      }
   }

   if ($opts{O}) {
      $buf .= _displayResultsOnlyOs($sinfp);
   }
   elsif ($opts{V}) {
      $buf .= _displayResultsOnlyOsAndVersionFamily($sinfp);
   }
   elsif ($opts{C}) {
      $buf .= _displayResultsAll($sinfp);
   }
   else {
      $buf .= _displayResultsShort($sinfp);
   }
   print $buf;
}

sub displayPassiveResult {
   my $sinfp = shift;
   my $frame = $sinfp->passiveFrame;

   print $frame->l3->src.':'.$frame->l4->src.' > '.
         $frame->l3->dst.':'.$frame->l4->dst;

   $frame->l4->haveFlagAck ? print " [SYN|ACK]\n"
                           : print " [SYN]\n";

   $sinfp->analyzeResponses;
   $opts{A} ? $sinfp->matchOsfps($opts{A}) : $sinfp->matchOsfps;

   displayResults($sinfp);
}

sub createAnonymizedPcapFile {
   my $sinfp = shift;

   use Net::Packet::Consts qw(:dump);
   $Env->noDumpAutoSet(1);
   require Net::Packet::Dump;
   my $in = Net::Packet::Dump->new(
      file      => $sinfp->_dump->file,
      overwrite => 0,
      mode      => NP_DUMP_MODE_OFFLINE,
   );
   $in->start;
   $in->nextAll;
   $in->stop;

   my @new;
   my $src = ($in->frames)[0]->l3->src;
   $Env->noFramePadding(1);
   for ($in->frames) {
      if ($_->l3->src eq $src) {
         $_->l3->src('127.0.0.1');
         $_->l3->dst('127.0.0.2');
         $_->l3->checksum(666);
         $_->l4->checksum(666);
      }
      else {
         $_->l3->src('127.0.0.2');
         $_->l3->dst('127.0.0.1');
         $_->l3->checksum(666);
         $_->l4->checksum(666);
      }
      $_->pack;
      push @new, $_;
   }

   my $anon = $sinfp->_dump->file;
   $anon =~ s/\.pcap$/.anon.pcap/;
   $anon =~ s/^(sinfp\d\-)\d+\.\d+\.\d+\.\d+\.\d+(\..*)$/${1}127.0.0.1${2}/;
   my $out = Net::Packet::Dump->new(
      file      => $anon,
      overwrite => 1,
      mode      => NP_DUMP_MODE_WRITER,
   );
   $out->start;
   $out->write($_) for @new;
   $out->stop;

   print "\n*** File [$anon] generation done.".
         "\n*** Please send it to sinfp\@gomor.org if you think this is not ".
         "\n*** the good identification, or if it is a new signature.".
         "\n*** In this last case, please specify `uname -a' (or equivalent) ".
         "\n*** from the target host.\n";

}
