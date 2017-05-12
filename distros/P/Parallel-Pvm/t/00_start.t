#!perl -w
#
# Title           : 00_start.t
# Description     : test for the start_pvmd function
# Author          : Denis leconte
# Date            : 11/15/2001
# 

use strict;
use Test;
BEGIN { plan tests => 1 }

use Parallel::Pvm;

# This calls start_pvmd to start PVM.
# If pvmd is already running, we get a "duplicate host" error,
# which is actually OK.
# I know, it's not the most elegant thing, but...

my $inum = Parallel::Pvm::start_pvmd();
ok(($inum == 0) || ($inum == Parallel::Pvm::PvmDupHost));

