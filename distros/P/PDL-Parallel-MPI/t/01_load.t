#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { print "1..2\n"; }

use PDL;
BEGIN { print "ok 1\n"; }

use PDL::Parallel::MPI;
BEGIN { print "ok 2\n"; }
