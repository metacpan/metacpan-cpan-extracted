use PDL;
use PDL::Char;
use PDL::IO::HDF5;
use PDL::Types;

# Script to test the PDL::IO::HDF5 objects together in the
#   way they would normally be used
#
#  i.e. the way they would normally be used as described
#  in the PDL::IO::HDF5 synopsis

use Test::More tests => 33;

# New File Check:
my $filename = "total.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

my $hdfobj;
ok($hdfobj = new PDL::IO::HDF5($filename));


# Set attribute for file (root group)
ok($hdfobj->attrSet( 'attr1' => 'dudeman', 'attr2' => 'What??'));

# Try Setting attr for an existing attr
ok($hdfobj->attrSet( 'attr1' => 'dudeman23'));


# Add a attribute and then delete it
ok($hdfobj->attrSet( 'dummyAttr' => 'dummyman', 
				'dummyAttr2' => 'dummyman'));
				
ok($hdfobj->attrDel( 'dummyAttr', 'dummyAttr2' ));


# Get list of attributes
my @attrs = $hdfobj->attrs;
ok(join(",",sort @attrs) eq 'attr1,attr2' );

# Get a list of attribute values
my @attrValues = $hdfobj->attrGet(sort @attrs);

ok(join(",",@attrValues) eq 'dudeman23,What??' );
# print "Attr Values = '".join("', '",@attrValues)."'\n";

##############################################

# Create a dataset in the root group
my $dataset = $hdfobj->dataset('rootdataset');

my $pdl = sequence(5,4);


ok($dataset->set($pdl) );
# print "pdl written = \n".$pdl."\n";

# Create String dataset using PDL::Char
my $dataset2 = $hdfobj->dataset('charData');

my $pdlChar = new PDL::Char( [ ["abccc", "def", "ghi"],["jkl", "mno", 'pqr'] ] );
 
ok($dataset2->set($pdlChar));


my $pdl2 = $dataset->get;
# print "pdl read = \n".$pdl2."\n";

ok((($pdl - $pdl2)->sum) < .001 );


my @dims = $dataset->dims;

ok( join(", ",@dims) eq '5, 4' );

# Get a list of datasets (should be two)
my @datasets = $hdfobj->datasets;

ok( scalar(@datasets) == 2 );


#############################################

my $group = $hdfobj->group("mygroup");

my $subgroup = $group->group("subgroup");

### Try a non-deault data-set type (float) ####
# Create a dataset in the subgroup
$dataset = $subgroup->dataset('my dataset');

$pdl = sequence(5,4)->float; # Try a non-default data type


ok( $dataset->set($pdl) );
# print "pdl written = \n".$pdl."\n";


$pdl2 = $dataset->get;
# print "pdl read = \n".$pdl2."\n";

ok( (($pdl - $pdl2)->sum) < .001 );

# Check for the PDL returned being a float
ok( ($pdl->get_datatype - $PDL_F) < .001 );

# Get a hyperslab
$pdl = $dataset->get(pdl([0,0]), pdl([4,0]));  # Get the first vector of the PDL

# Check to see if the dims are as expected.
my @pdlDims = $pdl->dims;
ok(  ($pdlDims[0] == 5) && ($pdlDims[1] == 1));


### Try a non-deault data-set type (int/long) ####
# Create a dataset in the subgroup
$dataset = $subgroup->dataset('my dataset2');

$pdl = sequence(5,4)->long; # Try a non-default data type


ok( $dataset->set($pdl) );
# print "pdl written = \n".$pdl."\n";


$pdl2 = $dataset->get;
# print "pdl read = \n".$pdl2."\n";

ok( (($pdl - $pdl2)->sum) < .001 );

# Check for the PDL returned being a int/long
ok( ($pdl->get_datatype - $PDL_L) < .001 );


################ Set Attributes at the Dataset Level ###############			
					
# Set attribute for group
ok( $dataset->attrSet( 'attr1' => 'DSdudeman', 'attr2' => 'DSWhat??'));

# Try Setting attr for an existing attr
ok($dataset->attrSet( 'attr1' => 'DSdudeman23'));


# Add a attribute and then delete it
ok( $dataset->attrSet( 'dummyAttr' => 'dummyman', 
				'dummyAttr2' => 'dummyman'));
				
ok( $dataset->attrDel( 'dummyAttr', 'dummyAttr2' ));


# Get list of attributes
@attrs = $dataset->attrs;
ok( join(",",sort @attrs) eq 'attr1,attr2' );

# Get a list of attribute values
@attrValues = $dataset->attrGet(sort @attrs);

ok( join(",",@attrValues) eq 'DSdudeman23,DSWhat??' );

################ Set Attributes at the Group Level ###############			
					
# Set attribute for group
ok( $group->attrSet( 'attr1' => 'dudeman', 'attr2' => 'What??'));

# Try Setting attr for an existing attr
ok($group->attrSet( 'attr1' => 'dudeman23'));


# Add a attribute and then delete it
ok( $group->attrSet( 'dummyAttr' => 'dummyman', 
				'dummyAttr2' => 'dummyman'));
				
ok( $group->attrDel( 'dummyAttr', 'dummyAttr2' ));


# Get list of attributes
@attrs = $group->attrs;
ok( join(",",sort @attrs) eq 'attr1,attr2' );

# Get a list of datasets (should be none)
@datasets = $group->datasets;

ok( scalar(@datasets) == 0 );

# Create another group
my $group2 = $hdfobj->group("dude2");


# Get a list of groups in the root group
my @groups = $hdfobj->groups;

# print "Root group has these groups '".join(",",sort @groups)."'\n";
ok( join(",",sort @groups) eq 'dude2,mygroup' );


# Get a list of groups in group2 (should be none)
@groups = $group2->groups;

ok( scalar(@groups) == 0 );

# print "completed\n";
