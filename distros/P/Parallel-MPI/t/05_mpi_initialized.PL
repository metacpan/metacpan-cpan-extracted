#!/usr/bin/perl -w

use strict;
use Config;
use Cwd;

my $file = "t/05_mpi_initialized.pl";
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
  $init = MPI_Initialized();
};

if ($@ || ! $init) {
   print "$@\n";
   print "not procok $rank\n" 
} else {
   print "procok $rank\n";
}

MPI_Finalize();
