#!perl -w
#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision: 1.5 $
# Author          : Ulrich Pfeifer
# Created On      : Wed Feb 21 22:17:41 2001
# Last Modified By: Sven Neuhaus
# Last Modified On: Fri Sep 21 11:03:36 2001
# Language        : CPerl
# 
# (C) Copyright 2001, UUNET Deutschland GmbH, Germany
# 

use strict;
use Test;
BEGIN { plan tests => 6 }

my $msg = '';
my @l = ("a" .. "z", "A" .. "Z", "0" .. "9");
$msg .= $l[rand(@l)] while length($msg) < 200_000;

my $recipient = recipient(); sleep 1;
my $sender    = sender();

$Test::ntest = 4;
ok(wait() == $sender);
ok($? == 0);
#kill(9, $recipient);
ok(wait() == $recipient);

sub recipient {
  if (my $pid = fork()) {
    return($pid)
  }
  require Parallel::Pvm;
  print "$$ tid=", Parallel::Pvm::mytid(), "\n";
  print "$$ going to read\n";
  my $bufid = Parallel::Pvm::recv();
  print "$$ got message\n";
  ok($bufid != 0);

  my ($info,$bytes,$tag,$stid) = Parallel::Pvm::bufinfo($bufid);
  print "$$ ran bufinfo\n";
  ok($info == 0);

  my $data = Parallel::Pvm::unpack($bytes);
  print "$$ got ", length($data), " bytes\n";
  ok($data eq $msg);
  sleep 1;
  exit 0;
}

sub sender {
  if (my $pid = fork()) {
    return($pid)
  }
  require Parallel::Pvm;
  my $target = Parallel::Pvm::mytid() - 1; # This is a hack

  print "$$ tid=", Parallel::Pvm::mytid(), "\n";
  Parallel::Pvm->import();
  print "$$ initializing\n";
  Parallel::Pvm::initsend(PvmDataRaw());
  print "$$ packing message\n";
  Parallel::Pvm::pack($msg);

  print "$$ sending message to $target\n";
  my $info = Parallel::Pvm::send($target, 0);
  exit $info;
}

