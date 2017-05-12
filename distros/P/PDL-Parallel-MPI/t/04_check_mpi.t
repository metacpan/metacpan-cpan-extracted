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
print "initialized ok\n" if MPI_Initialized();
$rank = MPI_Comm_rank(MPI_COMM_WORLD);
print "\nI am $rank\n";
send_test(4,1) if $rank == 0;
if ($rank == 1) {
	print (receive_test(0) == 4 ? "ok 2\n": "nok 2\n");
}
MPI_Finalize();
