# Script to test the PDL::IO::HDF5 objects together in the
#   way they would normally be used
#
#  i.e. the way they would normally be used as described
#  in the PDL::IO::HDF5 synopsis

use strict;
use warnings;
use PDL;
use PDL::Char;
use PDL::IO::HDF5;
use Test::More;

# New File Check:
my $filename = "total.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

ok(my $hdfobj = new PDL::IO::HDF5($filename));

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
is(join(",",sort @attrs), 'attr1,attr2' );

# Get a list of attribute values
my @attrValues = $hdfobj->attrGet(sort @attrs);

is(join(",",@attrValues), 'dudeman23,What??' );

##############################################

# Create a dataset in the root group
my $dataset = $hdfobj->dataset('rootdataset');

my $pdl = sequence(5,4);

ok($dataset->set($pdl, unlimited => 1) );

# Create String dataset using PDL::Char
my $dataset2 = $hdfobj->dataset('charData');

my $pdlChar = new PDL::Char( [ ["abccc", "def", "ghi"],["jkl", "mno", 'pqr'] ] );
 
ok($dataset2->set($pdlChar, unlimited => 1));

my $pdl2 = $dataset->get;
ok((($pdl - $pdl2)->sum) < .001 );

my @dims = $dataset->dims;

is( join(", ",@dims), '5, 4' );

# Get a list of datasets (should be two)
my @datasets = $hdfobj->datasets;

is( scalar(@datasets), 2 );


#############################################

my $group = $hdfobj->group("mygroup");

my $subgroup = $group->group("subgroup");

### Try a non-deault data-set type (float) ####
# Create a dataset in the subgroup
$dataset = $subgroup->dataset('my dataset');

$pdl = sequence(5,4)->float; # Try a non-default data type


ok( $dataset->set($pdl, unlimited => 1) );

$pdl2 = $dataset->get;

ok( (($pdl - $pdl2)->sum) < .001 );

# Check for the PDL returned being a float
is( $pdl->type, 'float' );

# Get a hyperslab
$pdl = $dataset->get(pdl([0,0]), pdl([4,0]));  # Get the first vector of the PDL

# Check to see if the dims are as expected.
my @pdlDims = $pdl->dims;
is_deeply( \@pdlDims, [5, 1] );


### Try a non-default data-set type (int/long) ####
# Create a dataset in the subgroup
$dataset = $subgroup->dataset('my dataset2');

$pdl = sequence(5,4)->long; # Try a non-default data type


ok( $dataset->set($pdl, unlimited => 1) );

$pdl2 = $dataset->get;

ok( (($pdl - $pdl2)->sum) < .001 );

# Check for the PDL returned being a int/long
is( $pdl->type, 'long' );

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
is( join(",",sort @attrs), 'attr1,attr2' );

# Get a list of attribute values
@attrValues = $dataset->attrGet(sort @attrs);

is( join(",",@attrValues), 'DSdudeman23,DSWhat??' );

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
is( join(",",sort @attrs), 'attr1,attr2' );

# Get a list of datasets (should be none)
@datasets = $group->datasets;

is( scalar(@datasets), 0 );

# Create another group
my $group2 = $hdfobj->group("dude2");

# Get a list of groups in the root group
my @groups = $hdfobj->groups;

is( join(",",sort @groups), 'dude2,mygroup' );

# Get a list of groups in group2 (should be none)
@groups = $group2->groups;

is( scalar(@groups), 0 );

done_testing;
