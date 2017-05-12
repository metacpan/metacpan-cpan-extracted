#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..2\n"; 
		$ret = system("mpirun -np 3 $0 yes");
		print STDERR "mpirun error\n" if $ret;
		print ($ret == 0 ? "ok 2\n" : "nok 2\n");
		exit;
	}
}

use PDL;
use PDL::Parallel::MPI;

MPI_Init();
$rank = get_rank();
$a=$rank * ones(2);
$b=($rank+2)**2 * ones(2);
print "rank = $rank $a $b\n";
$a->mpi_rotate(dest=>$b);
print "rank = $rank $a $b\n";
$b->set(0,- $b->at(0));
$b->mpi_rotate(dest=>$a, offset=>-1);
print "rank = $rank $a $b\n";
if ($rank == 1) { 
	if ( $a->at(0) == -1 and $b->at(1) == 0 ) {
		print "ok 1\n";
	} else {
		print "nok 1\n";
	}
}
MPI_Finalize();
