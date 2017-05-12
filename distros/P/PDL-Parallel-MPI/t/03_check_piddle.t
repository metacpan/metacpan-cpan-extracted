#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
BEGIN {print "1..2\n"; }
use PDL;
use PDL::Parallel::MPI;

print "ok 1\n";
$a= sequence 2,2,2;
print $a;
PDL::Parallel::MPI::check_piddle($$a);
print "ok 2\n";
