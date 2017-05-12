#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..2\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a=$rank * (sequence(4)+1);

$b=$a->scan; #use default op=>'+'
$c=$a->scan(op=>'max');
print "rank = $rank, b=$b\n" ;
print "rank = $rank, c=$c\n" ;

print "ok 1\n"  if $rank == 2 && sum($b- pdl [3,6,9,12]) == 0;
print "nok 1\n"  if $rank == 2 && sum($b- pdl [3,6,9,12]) != 0;
print "ok 2\n" if $rank == 2 && sum($c- pdl [2,4,6,8]) == 0;
print "nok 2\n" if $rank == 2 && sum($c- pdl [2,4,6,8]) != 0;

MPI_Finalize();
