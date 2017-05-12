#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..1\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a= sequence(4,4);
print "rank=$rank a=$a\n" if $rank == 0;
$b=$a->scatter;
print "rank=$rank b=$b\n";
print "ok 1\n"  if $rank == 3 && $b->at(3) == 15 ;
print "nok 1\n" if $rank == 3 && $b->at(3) != 15 ;
MPI_Finalize();
