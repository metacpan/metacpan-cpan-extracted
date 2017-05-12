#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
	use PDL;
	use PDL::Parallel::MPI;
	mpirun(2);

	MPI_Init();
	$rank = get_rank();
	$a=$rank * ones(4);
	print "my rank is $rank and \$a is $a\n";
	$a->move( 1 => 0);
	print "my rank is $rank and \$a is $a\n";
	print "1..1\n" if $rank == 0;
	print (sum($a) == 4 ? "ok 1\n" : "nok 1\n") if $rank == 0;
	MPI_Finalize();
