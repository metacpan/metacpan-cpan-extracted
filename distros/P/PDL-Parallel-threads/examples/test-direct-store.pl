use strict;
use warnings;

use PDL;
use PDL::Parallel::threads qw(retrieve_pdls);
use PDL::Parallel::threads::SIMD qw(parallel_sync parallelize parallel_id);
my $piddle = zeroes(20)->share_as('test');

my $N_threads = 5;

use PDL::NiceSlice;
parallelize {
	my $tid = parallel_id;
	my $piddle = retrieve_pdls('test');
	
	print "Thread id $tid says the piddle is $piddle\n";
	parallel_sync;

	my $N_data_to_fix = $piddle->nelem / $N_threads;
	my $idx = sequence($N_data_to_fix) * $N_threads + $tid;
	$piddle($idx) .= $tid;
	parallel_sync;
	
	print "After set, thread id $tid says the piddle is $piddle\n";
	parallel_sync;
	
	$piddle->set($tid, 0);
	parallel_sync;
	
	print "Thread id $tid says the piddle is now $piddle\n";
} $N_threads;


#my $piddle = retrieve_pdls('test');
print "Final piddle value is $piddle\n";
