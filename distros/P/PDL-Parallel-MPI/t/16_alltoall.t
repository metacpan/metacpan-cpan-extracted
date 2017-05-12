#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..1\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a=$rank * (sequence(4)+1);
$b=zeroes($a->dims);


if ($rank == 2) {
	print "rank = $rank, a=$a\n";
	print "rank = $rank, b=$b\n";
}
$b=$a->alltoall;
if ($rank == 2) {
	print "rank = $rank, a=$a\n" ;
	print "rank = $rank, b=$b\n" ;
}
print "ok 1\n"  if $rank == 2 && sum($b- pdl [0,3,6,9]) == 0;
print "nok 1\n" if $rank == 2 && sum($b- pdl [0,3,6,9]) != 0;

MPI_Finalize();
