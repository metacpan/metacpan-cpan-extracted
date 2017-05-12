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
use Data::Dumper;

MPI_Init();
$rank = MPI_Comm_rank(MPI_COMM_WORLD);
$a=$rank * ones(2,2);
print "rank = $rank".$a;
PDL::Parallel::MPI::xs_send($$a,1)    if $rank == 0;
PDL::Parallel::MPI::xs_receive($$a,0) if $rank == 1;
print Dumper get_status();
print "rank = $rank".$a;
print (sum($a) == 0 ? "ok 1\n" : "nok 1\n") if $rank ==1;
MPI_Finalize();
