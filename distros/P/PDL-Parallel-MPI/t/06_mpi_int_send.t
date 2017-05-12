#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

BEGIN { 
	unless (@ARGV) {
		print "1..2\n"; 
		$ret = system("mpirun -np 2 $0 yes");
		print ($ret ? "nok 2\n" : "ok 2\n") ;
		exit;
	}
}


$|=1;
use PDL;
use PDL::Parallel::MPI;

MPI_Init();

$my_rank = MPI_Comm_rank(MPI_COMM_WORLD);
$p = MPI_Comm_size(MPI_COMM_WORLD);

#print "pid = $$, rank = $my_rank\n";
$tag = 0;
if ($my_rank != 0) {
    $message = 31337;
    $dest = 0;
    
    MPI_Send(\$message, 1, MPI_INT, $dest, $tag, MPI_COMM_WORLD);
} else { 
    # my_rank == 0
    for $source (1..$p-1) {
	@status = MPI_Recv(\$message, 1, MPI_INT, $source, $tag, 
			   MPI_COMM_WORLD);	
	
	printf("Recieved: \"%s\" from $source\n", $message);
	printf("Status: (" . (join ', ',@status) . ")\n");
        if($message == 31337) {
	    print "ok 1\n";
        } else {
            print "MESSAGE: $message\nnot ok 1\n";
        }
	# (count,MPI_SOURCE,MPI_TAG,MPI_ERROR)
    }
}

MPI_Finalize();

