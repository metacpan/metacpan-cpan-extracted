#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
use strict;
use PDL;
use utils;

run_benchmark();

sub run_benchmark 
{
	my (@c_send,@c_recv,@prl_send,@prl_recv,@pdl_send,@pdl_recv);
	system("mpicc -lm send_receive.c");
	for my $i (0 .. 9) 
	{
		print "running: $i (Parallel::MPI)\n";
		system("mpirun -machinefile ./where -np 2 ./parallel_mpi_bench.pl > out");
		open INPUT, "out";
		$prl_recv[$i] = get(\*INPUT);
		$prl_send[$i] = get(\*INPUT);
		close INPUT;

		print "running: $i (PDL)\n";
		system("mpirun -machinefile ./where -np 2 ./move_time.pl > out");
		open INPUT, "out";
		$pdl_recv[$i] = get(\*INPUT);
		$pdl_send[$i] = get(\*INPUT);
		close INPUT;
	
		print "running: $i (MPI/C)\n";
		system("mpirun -machinefile ./where -np 2 ./a.out > out");
		open INPUT, "out";
		$c_recv[$i] = get(\*INPUT);
		$c_send[$i] = get(\*INPUT);
		close INPUT;
	}
		my $prl_recv = adj(@prl_recv);
		my $prl_send = adj(@prl_send);

		my $pdl_recv = adj(@pdl_recv);
		my $pdl_send = adj(@pdl_send);

		my $c_recv = adj(@c_recv);
		my $c_send = adj(@c_send);

		print "got here\n";
		our @results;
		foreach ($prl_send,$prl_recv,$pdl_send, $pdl_recv,$c_send,$c_recv) 
		{
			my ($mean,$rms) = statsover($_);
			push @results,($mean,$rms);
		}

		my $results = cat(@results);
		$results->put('results');
}
