#!/usr/bin/perl
#
# $Id: sinfp3-mode-active.pl,v 4227384cc2ea 2012/08/31 11:50:38 gomor $
#
use strict;
use warnings;

my $target = shift || die("You must specify target IP address\n");
my $port   = shift || die("You must specify target open TCP port\n");
my $file   = shift || die("You must specify sinfp3.db file\n");

use Net::SinFP3;
use Net::SinFP3::Log::Console;
use Net::SinFP3::Global;

use Net::SinFP3::Input::IpPort;
use Net::SinFP3::DB::SinFP3;
use Net::SinFP3::Mode::Active;
use Net::SinFP3::Search::Active;
use Net::SinFP3::Output::Console;

my $log = Net::SinFP3::Log::Console->new(
   level => 3,
);

my $global = Net::SinFP3::Global->new(
   log    => $log,
   target => $target,
   ipv6   => 0,
) or exit(1);

my $input = Net::SinFP3::Input::IpPort->new(
   global => $global,
   ip     => $target,
   port   => $port,
);

my $db = Net::SinFP3::DB::SinFP3->new(
   global => $global,
   file   => $file,
);

my $mode = Net::SinFP3::Mode::Active->new(
   global => $global,
   doP1   => 1,
   doP2   => 1,
   doP3   => 1,
);

my $search = Net::SinFP3::Search::Active->new(
   global => $global,
);

my $output = Net::SinFP3::Output::Console->new(
   global => $global,
);

my $sinfp = Net::SinFP3->new(
   global => $global,
   input  => [ $input  ],
   db     => [ $db     ],
   mode   => [ $mode   ],
   search => [ $search ],
   output => [ $output ],
);

$sinfp->run;
$log->post;

exit(0);
