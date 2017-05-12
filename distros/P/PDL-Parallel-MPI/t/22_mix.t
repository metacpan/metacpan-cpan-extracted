#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
	use PDL;
	use PDL::Parallel::MPI;
	mpirun(2);

	MPI_Init();
	$rank = get_rank();
	$pi = 3.1;
	if ($rank == 0) {
		MPI_Send(\$pi,1,MPI_DOUBLE,1,0,MPI_COMM_WORLD);
	} else {
		$message = zeroes(1);
		$message->receive(0);
		print "pi is $message\n";
		print "1..1\n";
		print ($message->at(0) == 3.1 ? "ok 1\n" : "nok 1\n");
	}
	MPI_Finalize();
