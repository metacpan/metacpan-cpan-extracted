#!/usr/bin/perl -w

use strict;
use Config;
use Cwd;

my $file = "t/10_mpi_wtime.pl";
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

my $rank = MPI_Comm_rank(MPI_COMM_WORLD);

eval {
  $start = MPI_Wtime();
};

if($rank == 0) {
    if ($@ || ! $start) {
       print "$@\n";
       print "not ok 1\n"
    } else {
       print "ok 1\n";
    }
}

sleep(1);


eval {
  $stop = MPI_Wtime();
};

print "Start=$start, Stop=$stop\n";

if($rank == 0) {
    if ($@ || ! $stop || $stop < $start) {
       print "$@\n";
       print "not ok 2\n" 
    } else {
       print "ok 2\n";
    }
}

MPI_Finalize();
