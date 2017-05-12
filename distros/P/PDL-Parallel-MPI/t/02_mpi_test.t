#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..2\n"; 
		print "ok 1\n";
		$ret = system("mpirun -np 2 $0 yes");
		print STDERR "mpirun error\n" if $ret;
		exit;
	}
}

use PDL;
use PDL::Parallel::MPI;

MPI_Init();
$rank = MPI_Comm_rank(MPI_COMM_WORLD);
print "\nI am $rank\n";
print "ok 2\n" if $rank == 1;
MPI_Finalize();
