# Test case for HDF5 unlink function
use strict;
use warnings;
use PDL;
use PDL::IO::HDF5;
use Test::More;

my $filename = "unlink.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

my $hdf5 = new PDL::IO::HDF5($filename);

my $group=$hdf5->group('group1');

# Store a dataset
my $dataset=$group->dataset('data1');
my $data = pdl [ 2.0, 3.0, 4.0 ];
$dataset->set($data, unlimited => 1);

my $expected = 'data1';
my @datasets1=$group->datasets();
#print "datasets '".join(", ",@datasets1)."'\n";
is(join(', ',@datasets1), $expected);

# Remove the dataset.
$group->unlink('data1');

$expected = '';
my @datasets2=$group->datasets();
#print "datasets '".join(", ",@datasets2)."'\n";
is(join(', ',@datasets2), $expected);

# clean up file
unlink $filename if( -e $filename);

done_testing;
