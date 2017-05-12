#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

print "1..2\n" if not @ARGV;
use PDL;
use PDL::Parallel::MPI;
mpirun(4);

MPI_Init();
$rank = get_rank();
$a=$rank * (sequence(4)+1);

$b=$a->reduce; #use default op=>'+'
$c=$a->reduce(op=>'max');
if ($rank == 0) {
	print "rank = $rank, b=$b\n" ;
	print "rank = $rank, c=$c\n" ;
}
print "ok 1\n"  if $rank == 0 && sum($b- pdl [6,12,18,24]) == 0;
print "nok 1\n"  if $rank == 0 && sum($b- pdl [6,12,18,24]) != 0;
print "ok 2\n" if $rank == 0 && sum($c- pdl [3,6,9,12]) == 0;
print "nok 2\n" if $rank == 0 && sum($c- pdl [3,6,9,12]) != 0;

MPI_Finalize();
