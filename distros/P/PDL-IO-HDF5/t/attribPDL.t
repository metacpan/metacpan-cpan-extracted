use PDL;
use PDL::Char;
use PDL::IO::HDF5;
use PDL::Types;

BEGIN {
use Config;
our $have_LL = $Config{ivsize} == 4 ? 0 : 1;
our $tests = $have_LL ? 13 : 11;
};


# Test case for HDF5 attributes that are pdls 
#   This is a new feature as-of version 0.64
#
use Test::More tests => $tests;

my $filename = "newFile.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

my $hdf5 = new PDL::IO::HDF5($filename);


# Create pdls to store:
my $pchar = PDL::Char->new( [['abc', 'def', 'ghi'],['jkl', 'mno', 'pqr']] );
my $bt=pdl([[1.2,1.3,1.4],[1.5,1.6,1.7],[1.8,1.9,2.0]]);

my $group=$hdf5->group('Radiometric information');

# Store a dataset
my $dataset=$group->dataset('SP_BT');
$dataset->set($bt);

# Store a scalar and pdl attribute
$dataset->attrSet('UNITS'=>'K');
$dataset->attrSet('NUM_COL'=>pdl(long,[[1,2,3],[4,5,6]]));
$dataset->attrSet('NUM_COLLONG'=>pdl(longlong,[[123456789123456784,2,3],[4,5,6]]))
  if $have_LL;
$dataset->attrSet('NUM_ROW'=>$pchar);
$dataset->attrSet('SCALING'=>'pepe');
$dataset->attrSet('OFFSET'=>pdl(double,[0.0074]));
$dataset->attrSet('ID'=>pdl(long,87));
$dataset->attrSet('IDLONG'=>pdl(longlong,123456789123456784))
  if $have_LL;
$dataset->attrSet('TEMPERATURE'=>pdl(double,3.1415927));

# Set group attribute
$group->attrSet('GroupPDLAttr'=>pdl(long,[[1,2,3],[4,5,6]]));

######## Now Read HDF5 file  #####
my $hdf2= new PDL::IO::HDF5($filename);
my $group2=$hdf2->group('Radiometric information');
my $dataset2=$group2->dataset('SP_BT');
my $expected;


$expected = '
[
 [1.2 1.3 1.4]
 [1.5 1.6 1.7]
 [1.8 1.9   2]
]
';
my $bt2=$dataset2->get();
#print "expoected = '$bt2'\n";
ok("$bt2" eq $expected);	#1

$expected = 'K';
my ($units)=$dataset2->attrGet('UNITS');
#print "units '$units'\n";
ok($units eq $expected);	#2


$expected = '
[
 [1 2 3]
 [4 5 6]
]
';
my ($numcol)=$dataset2->attrGet('NUM_COL');
#print "numcol '$numcol'\n";
ok("$numcol" eq $expected);	#3

ok((ref($numcol) && $numcol->isa('PDL')) );	#4

if($have_LL) {
  $expected = '123456789123456784                  2                  3                  4                  5                  6';
  my ($numcollong)=$dataset2->attrGet('NUM_COLLONG');
  #print "numcollong '$numcollong'\n";
  ok(sprintf("%18i %18i %18i %18i %18i %18i",$numcollong->list()) eq $expected);
}

$expected = "[
 [ 'abc' 'def' 'ghi'  ] 
 [ 'jkl' 'mno' 'pqr'  ] 
] 
";
my ($numrow)=$dataset2->attrGet('NUM_ROW');
#print "numrow '$numrow'\n";
ok("$numrow" eq $expected);

$expected = 'pepe';
my ($scaling)=$dataset2->attrGet('SCALING');
#print "scaling '$scaling\n";
ok($scaling eq $expected);


$expected = '[0.0074]';
my ($offset)=$dataset2->attrGet('OFFSET');
#print "offset '$offset'\n";
ok("$offset" eq $expected);


$expected = '87';
my ($id)=$dataset2->attrGet('ID');
#print "id '$id'\n";
ok("$id" eq $expected);

if($have_LL) {
  $expected = '123456789123456784';
  my ($idlong)=$dataset2->attrGet('IDLONG');
  #print "idlong '$idlong'\n";
  ok("$idlong" eq $expected);
}


$expected = '3.1415927';
my ($temperature)=$dataset2->attrGet('TEMPERATURE');
#print "temperature '$temperature'\n";
ok("$temperature" eq $expected);


# Check Group PDL Attribute
$expected = '
[
 [1 2 3]
 [4 5 6]
]
';
my ($numcol2)=$group2->attrGet('GroupPDLAttr');
#print "numcol '$numcol'\n";
ok("$numcol2" eq $expected);
ok((ref($numcol2) && $numcol2->isa('PDL')) );

# clean up file
unlink $filename if( -e $filename);
