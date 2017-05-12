#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..2\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a=($rank+1) * sequence(4);


$b = $a->allgather();
print "rank = $rank, b=$b" if $rank == 1;

print "ok 1\n"  if $rank ==1 && $b->at(1,3) == 4;
print "nok 1\n" if $rank ==1 && $b->at(1,3) != 4;

$c = zeroes(16);
allgather( 
	source 	=> $a ,
	dest	=> $c 
	);
print "rank = $rank, c=$c\n" if $rank == 1;
print "ok 2\n"  if $rank ==1 && $c->at(14) == 8;
print "nok 2\n" if $rank ==1 && $c->at(14) != 8;

MPI_Finalize();
