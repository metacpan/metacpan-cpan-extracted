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
use Data::Dumper;

MPI_Init();
$rank = get_rank();
$a=$rank * ones(2);
print "rank = $rank piddle=$a\n";
$a->broadcast(3);
print "rank = $rank piddle=$a\n";
print (sum($a) == 6 ? "ok 1\n" : "nok 2\n") if $rank == 0;
MPI_Finalize();


