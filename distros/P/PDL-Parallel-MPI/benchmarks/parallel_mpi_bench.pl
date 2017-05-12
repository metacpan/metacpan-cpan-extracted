#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
use Parallel::MPI qw(:all);
use PDL;
$how_many=18;
$nk = 10;
MPI_Init();
$rank = MPI_Comm_rank(MPI_COMM_WORLD);

foreach $i (0 .. $nk-1) 
{
	foreach $k (0 .. $how_many -1) 
	{
		$size = 2**$k;
		@to_send = (0 .. $size-1);
		MPI_Barrier(MPI_COMM_WORLD);
		$start = MPI_Wtime();
		MPI_Send(\@to_send,$size,MPI_DOUBLE,0,0,MPI_COMM_WORLD) if $rank == 1;
		MPI_Recv(\@to_send,$size,MPI_DOUBLE,1,0,MPI_COMM_WORLD) if $rank == 0;
		$finish = MPI_Wtime() - $start;
		$result[$i][$k]  = $finish;
	}
}

if ($rank == 0) {
	foreach $k (0 .. $how_many -1) {
		foreach $i (0 .. $nk-1) {
			printf "%f ", $result[$i][$k];
		}
		print "\n";
	}
}
MPI_Barrier(MPI_COMM_WORLD);
print "\n" if $rank == 0;
foreach $k (0 .. $how_many -1) {
	foreach $i (0 .. $nk-1) {
		$what = $result[$i][$k];
		MPI_Send(\$what,1,MPI_DOUBLE,0,0,MPI_COMM_WORLD) if $rank == 1;
		MPI_Recv(\$what,1,MPI_DOUBLE,1,0,MPI_COMM_WORLD) if $rank == 0;
		printf "%f ", $what if $rank ==0;
	}
	print "\n" if $rank == 0;
}
print "\n" if $rank == 0;


MPI_Finalize();;
