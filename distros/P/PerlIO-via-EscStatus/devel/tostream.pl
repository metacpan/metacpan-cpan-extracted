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


use strict;
use warnings;
use Time::HiRes;

use ProgressMonitor;
use ProgressMonitor::SetMessageFlags;
use ProgressMonitor::Stringify::Fields::Counter;
use ProgressMonitor::Stringify::Fields::Fixed;
use ProgressMonitor::Stringify::Fields::Spinner;

use ProgressMonitor::Stringify::ToStream;

# $| = 1;

my $mon = ProgressMonitor::Stringify::ToStream->new
  ({fields => [ProgressMonitor::Stringify::Fields::Counter->new ({digits=>2}),
               ProgressMonitor::Stringify::Fields::Fixed->new,
               ProgressMonitor::Stringify::Fields::Spinner->new,
              ]});
$mon->setMessage ("begin message", SM_BEGIN);

my $total = 10;
$mon->prepare;
$mon->begin ($total);

foreach my $i (1 .. $total) {
  $mon->tick (1);
  Time::HiRes::usleep (500_000);

  if ($i == int($total/3)) {
    $mon->setMessage ("hello\nworld", SM_END);
    # sleep (3);
  }
  if ($i == int($total*2/3)) {
    $mon->setErrorMessage ("error\nmessage");
  }
}
$mon->end;

exit 0;
