use PDL;
use PDL::IO::HDF5;
use PDL::Types;

# Test case for HDF5 references
#   This is a new feature as-of version 0.64
#
use Test::More tests => 2;

my $filename = "reference.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

my $hdf5 = new PDL::IO::HDF5($filename);

my $group=$hdf5->group('group1');

# Store a dataset
my $dataset=$hdf5->dataset('data1');
my $data = pdl [ 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0 ];
$dataset->set($data);

# create the reference
my @regionStart = ( 3 );
my @regionCount = ( 3 );
$hdf5->reference($dataset,"myRef",\@regionStart,\@regionCount);

$expected = 'data1, myRef';
my @datasets1=$hdf5->datasets();
#print "datasets '".join(", ",@datasets1)."'\n";
ok(join(', ',@datasets1) eq $expected);

# dereference the dataset
my $ref = $hdf5->dataset("myRef");
my $dereferenced = $ref->get();

$expected = '[5 6 7]';
#print "dereferenced '$dereferenced'\n";
ok("$dereferenced" eq $expected);

# clean up file
unlink $filename if( -e $filename);
