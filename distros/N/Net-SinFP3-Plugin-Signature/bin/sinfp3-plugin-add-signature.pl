#!/usr/bin/perl
#
# $Id: sinfp3-plugin-add-signature.pl 19 2012-09-11 12:40:54Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('s:6f:tnhvl:p', \%opts);

if ($opts{h} || !$opts{f} && !$opts{n}) {
   print "\n  -- SinFP3 plugin add signature --\n".
         "\n".
         "Usage: $0 [-f pcapFile | -n] [-s signatureFile] [-p] [-6] [-t] [-h] [-v]\n".
         "\n".
         "   -h        this help\n".
         "   -p        passive signature i/o active\n".
         "   -v        be verbose\n".
         "   -l N      verbose level\n".
         "   -f file   pcap file to read\n".
         "   -n        signature in Nessus format\n".
         "   -s db     signature file to use\n".
         "   -6        this is an IPv6 signature\n".
         "   -t        flag to indicate this is a trusted signature source\n".
         "";
   exit(0);
}

use Net::SinFP3;
use Net::SinFP3::Global;
use Net::SinFP3::DB::SinFP3;
#use Net::SinFP3::Input::Nessus;
use Net::SinFP3::Input::Pcap;
use Net::SinFP3::Mode::Active;
use Net::SinFP3::Mode::Passive;
use Net::SinFP3::Mode::Null;
use Net::SinFP3::Search::Active;
use Net::SinFP3::Search::Passive;
use Net::SinFP3::Output::AddSignature;
use Net::SinFP3::Output::AddSignatureP;
use Net::SinFP3::Log::Console;

$opts{6} ||= 0;

my $log = Net::SinFP3::Log::Console->new(
   level => $opts{v} ? ($opts{l} || 1) : 0,
);

my $global = Net::SinFP3::Global->new(
   log  => $log,
   ipv6 => $opts{6},
);

# Load database
my $db = Net::SinFP3::DB::SinFP3->new(
   global => $global,
   file   => $opts{s} || 'bin/sinfp3.db',
);

my $output;
my $search;
if ($opts{p}) {
   $output = Net::SinFP3::Output::AddSignatureP->new(
      global  => $global,
      trusted => $opts{t} ? 1 : 0,
   );
   $search = Net::SinFP3::Search::Passive->new(
      global => $global,
   );
}
else {
   $output = Net::SinFP3::Output::AddSignature->new(
      global  => $global,
      trusted => $opts{t} ? 1 : 0,
   );
   $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );
}

my $input;
my $mode;
if ($opts{n}) {
   $input = Net::SinFP3::Input::Nessus->new(
      global => $global,
   );
   $mode = Net::SinFP3::Mode::Null->new(
      global => $global,
   );
}
elsif ($opts{f}) {
   if ($opts{p}) {
      $input = Net::SinFP3::Input::Pcap->new(
         global => $global,
         file   => $opts{f},
      );
   }
   else {
      $input = Net::SinFP3::Input::Pcap->new(
         global => $global,
         file   => $opts{f},
         count  => 10,
      );
   }
   if ($opts{p}) {
      $mode = Net::SinFP3::Mode::Passive->new(
         global => $global,
      );
   }
   else {
      $mode = Net::SinFP3::Mode::Active->new(
         global => $global,
      );
   }
}

my $sinfp = Net::SinFP3->new(
   global => $global,
   db     => [ $db     ],
   input  => [ $input  ],
   search => [ $search ],
   output => [ $output ],
   mode   => [ $mode   ],
);

# Ready to go
$sinfp->run;
$log->post;

exit(0);
