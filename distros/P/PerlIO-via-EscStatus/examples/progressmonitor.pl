#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./progressmonitor.pl
#
# This is a sample of ProgressMonitor::Stringify::ToEscStatus which directs
# ProgressMonitor states to a stream with an EscStatus layer.
#
# As noted in the ToEscStatus docs you have to push an EscStatus layer
# yourself but beyond that the only change part is $mon created as a
# ToEscStatus where you'd otherwise use a ToStream.
#
# Incidentally, if you've got some code using ToStream it'll still work fine
# with the EscStatus layer pushed.  The prints from ToStream are "ordinary
# output" for the purposes of the layer and go out unmolested.
#

use strict;
use warnings;
use Time::HiRes qw(usleep);

use ProgressMonitor;
use ProgressMonitor::Stringify::Fields::Counter;
use ProgressMonitor::Stringify::Fields::Fixed;
use ProgressMonitor::Stringify::Fields::Spinner;

use PerlIO::via::EscStatus;
use ProgressMonitor::Stringify::ToEscStatus;

binmode (STDOUT, ':via(EscStatus)') or die $!;

my $mon = ProgressMonitor::Stringify::ToEscStatus->new
  ({fields => [ProgressMonitor::Stringify::Fields::Counter->new ({digits=>2}),
               ProgressMonitor::Stringify::Fields::Fixed->new,
               ProgressMonitor::Stringify::Fields::Spinner->new,
              ]});

my $total = 10;
$mon->prepare;
$mon->begin ($total);

foreach my $i (1 .. $total) {
  $mon->tick (1);
  usleep (500_000);

  if ($i == int($total/2)) {
    $mon->setMessage ('hello');
  }
}
$mon->end;

exit 0;
