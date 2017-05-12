#!/usr/bin/perl -w

use strict;
use Config;
use Cwd;

my $file = "t/08_mpi_reduce.pl";
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
my $from = $rank;

MPI_Reduce(\$from, \$to, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);

if ($rank == 0) {
     print "Reduction produced $to\n";    
     if ($to == 1) {
        print "ok 1\n";
     } else {
        print "not ok 1\n";     
     }
}

MPI_Finalize();

