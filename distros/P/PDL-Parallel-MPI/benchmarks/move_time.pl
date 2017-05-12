#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib

use PDL;
use PDL::Parallel::MPI;
MPI_Init();
$how_many=18;
$nk= 10;
$rank = get_rank();
$ts=sequence($how_many);
$test_sizes = 2 ** $ts;

$dataset = zeroes($nk,$how_many);

foreach $i (0 .. $nk-1) 
{
	foreach $k (0 .. $how_many -1) 
	{
		$piddle = $rank * ones(  $test_sizes->at($k));
		MPI_Barrier(MPI_COMM_WORLD);
		$start = MPI_Wtime();
		$piddle->move(1=>0);
		$finish = MPI_Wtime() - $start;
		$dataset->slice("$i,$k") .= $finish;
	}
}

$dataset->print_ascii if $rank == 0;
$dataset->move(1=>0);
print "\n" if $rank == 0;
$dataset->print_ascii if $rank == 0;



MPI_Finalize();

sub PDL::print_ascii {
	use strict;
	my $piddle=shift;
	for my $row (0 .. $piddle->getdim(1)-1) {
		for my $column (0 .. $piddle->getdim(0)-1) {
			printf "%f ", $piddle->at($column,$row);
		}
		print "\n";
	}
}
