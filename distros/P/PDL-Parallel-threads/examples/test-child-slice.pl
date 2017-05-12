use strict;
use warnings;

use PDL;
use PDL::Parallel::threads qw(retrieve_pdls);
use PDL::Parallel::threads::SIMD qw(parallelize);

my $N_threads = 5;

use PDL::NiceSlice;

my $piddle = zeroes(20);
my $slice = $piddle->(0:9);
print "piddle:\n";
$piddle->dump;
print "slice:\n";
$slice->dump;
my $second = sequence(20);
my $rotation = $second->rotate(5);
print "second:\n";
$second->dump;
print "rotation:\n";
$rotation->dump;
print "\n\n+++ Modified rotation/second +++\n";
$rotation++;
print "second:\n";
$second->dump;
print "rotation:\n";
$rotation->dump;

$piddle->dump;
$piddle->share_as('test');
$rotation->dump;	
$rotation->share_as('rotated');

parallelize {
	my $tid = shift;
	my ($piddle, $rotated) = retrieve_pdls('test', 'rotated');
	$piddle($tid) .= $tid;
	$rotated($tid) .= $tid;
} $N_threads;


print "Final piddle value is $piddle\n";
print "Slice is $slice\n";
print "Rotated piddle is $rotation\n";
print "Parent of rotated piddle $second\n";
