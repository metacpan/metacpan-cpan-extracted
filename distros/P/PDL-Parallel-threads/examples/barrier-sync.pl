use strict;
use warnings;

use PDL;
use PDL::NiceSlice;
use PDL::Parallel::threads qw(retrieve_pdls);
use PDL::Parallel::threads::SIMD qw(parallelize parallel_sync parallel_id);
my $piddle = zeroes(20);
$piddle->share_as('test');
#undef($piddle);

# Create and share a slice
my $slice = $piddle(10:15)->sever;
$slice->share_as('slice');

# Create and share a memory mapped piddle
use PDL::IO::FastRaw;
my $mmap = mapfraw('foo.bin', {Creat => 1, Datatype => double, Dims => [50]});
$mmap->share_as('mmap');

END {
	unlink 'foo.bin';
	unlink 'foo.bin.hdr';
}

my $N_threads = 5;

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

print "mmap is $mmap\n";
parallelize {
	my $tid = parallel_id;
	my $mmap = retrieve_pdls('mmap');
	
	$mmap($tid) .= $tid;
} $N_threads;

print "now mmap is $mmap\n";

parallelize {
	my $tid = parallel_id;
	my $piddle = retrieve_pdls('test');
	
	print "Thread id is $tid\n";
	
	my $N_data_to_fix = $piddle->nelem / $N_threads;
	my $idx = sequence($N_data_to_fix - 1) * $N_threads + $tid;
	use PDL::NiceSlice;
	$piddle($idx) .= -$tid;
	
	my $slice = retrieve_pdls('slice');
	$slice($tid) .= -10 * $tid;
} $N_threads;

print "Final piddle value is $piddle\n";
