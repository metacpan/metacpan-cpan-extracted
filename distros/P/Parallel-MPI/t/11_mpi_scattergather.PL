#!/usr/bin/perl -w

use strict;
use Config;
use Cwd;

my $file = "t/11_mpi_scattergather.pl";
local(*OUTF);

open(OUTF, ">$file") or die "Cannot open $file for writing: $!\n";

print OUTF $Config{startperl} . " -I" . Cwd::cwd . "/blib/arch" .
				" -I" . Cwd::cwd . "/blib/lib\n";
print "Writing $file\n";
while(<DATA>) { print OUTF $_ }
close(OUTF);
chmod(0755, $file);
__END__
$|=1;
use Parallel::MPI qw(:all);

MPI_Init();
$my_rank = MPI_Comm_rank(MPI_COMM_WORLD);

my $string = "12345678";

my $sendbuf = $string;
my $recvbuf;

print "RANK $my_rank: SCATTER\n";

MPI_Scatter(\$sendbuf, 4, MPI_CHAR,
	    \$recvbuf, 4, MPI_CHAR, 0, MPI_COMM_WORLD);

print "RANK $my_rank:  RECVBUF=\"$recvbuf\"\n";

$sendbuf = "scribble";

MPI_Gather(\$recvbuf, 4, MPI_CHAR,
	   \$sendbuf, 4, MPI_CHAR, 0, MPI_COMM_WORLD);

if ($my_rank == 0) {
    printf "FINAL BUF = $sendbuf\n";
    if ($sendbuf eq $string) {
    	print "ok 1\n";
    } else {
    	print "not ok 1\n";
    }
}

MPI_Finalize();

