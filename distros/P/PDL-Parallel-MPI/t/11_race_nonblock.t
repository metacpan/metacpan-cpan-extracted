#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..2\n"; 
		$ret = system("mpirun -np 4 $0 yes");
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
$b=$rank * ones(2);
print "rank = $rank $a $b \n";
$r_send 	= $a->send_nonblocking(($rank+1) % 4);
$r_receive  = $b->receive_nonblocking(($rank-1) % 4);
print "waiting on send ($rank)\n";
$r_send->wait;
print "waiting on receive ($rank)\n";
$r_receive->wait;
print "rank = $rank $a $b \n";
if ($rank == 1) { print ($b->at(0) == 0 ? "ok 1\n" : "nok 1\n"); }
MPI_Finalize();
