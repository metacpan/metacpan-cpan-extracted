#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..3\n"; 
		$ret = system("mpirun -np 3 $0 yes");
		print STDERR "mpirun error\n" if $ret;
		print ($ret == 0 ? "ok 3\n" : "nok 3\n");
		exit;
	}
}

use PDL;
use PDL::Parallel::MPI;

MPI_Init();
$rank = get_rank();
$a=$rank * ones(2);
print "rank = $rank".$a,"\n";
$a->mpi_rotate();
print "rank = $rank".$a,"\n";
if ($rank == 1){ print ($a->at(0) == 0 ? "ok 1\n" : "nok 1\n") }
$a->mpi_rotate(offset=>-1);
print "rank = $rank".$a,"\n";
if ($rank == 1){ print ($a->at(0) == 1 ? "ok 2\n" : "nok 2\n")}
MPI_Finalize();
