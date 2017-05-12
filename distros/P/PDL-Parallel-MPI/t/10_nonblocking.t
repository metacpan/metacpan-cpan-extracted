#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..2\n"; 
		$ret = system("mpirun -np 2 $0 yes");
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
print "rank = $rank".$a,"\n";
$r 	= $a->send_nonblocking(0) if $rank == 1;
$r 	= $a->receive_nonblocking(1) if $rank == 0;
print "waiting on communications (rank = $rank)\n";
$r->wait;
print "rank = $rank".$a,"\n";
if ($rank == 0) {print ($a->at(0) == 1 ? "ok 1\n" : "nok 1\n"); }
MPI_Finalize();
