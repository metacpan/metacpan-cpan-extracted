#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..1\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a=$rank * (sequence(4)+1);
$b=$a->reduce_and_scatter; 
print "rank = $rank, b=$b\n" ;

print "ok 1\n"   if $rank == 2 && sum($b) == 18;
print "nok 1\n"  if $rank == 2 && sum($b) != 18;

MPI_Finalize();
