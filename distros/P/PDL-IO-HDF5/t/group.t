use PDL;
use PDL::IO::HDF5;
use PDL::IO::HDF5::Group;
use PDL::IO::HDF5::Dataset;

# Script to test the group/dataset object separately.
#  i.e. not the way they would normally be used as described
#  in the PDL::IO::HDF5 synopsis

use Test::More tests => 17;

# New File Check:
my $filename = "newFile.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);

my $hdfobj;
ok($hdfobj = new PDL::IO::HDF5($filename));

my $group = new PDL::IO::HDF5::Group( name => '/dude', parent => $hdfobj,
					 fileObj => $hdfobj);
					
					
# Set attribute for group
ok($group->attrSet( 'attr1' => 'dudeman', 'attr2' => 'What??'));

# Try Setting attr for an existing attr
ok($group->attrSet( 'attr1' => 'dudeman23'));


# Add a attribute and then delete it
ok( $group->attrSet( 'dummyAttr' => 'dummyman', 
				'dummyAttr2' => 'dummyman'));
				
ok( $group->attrDel( 'dummyAttr', 'dummyAttr2' ));


# Get list of attributes
my @attrs = $group->attrs;
ok( join(",",sort @attrs) eq 'attr1,attr2' );

# Get a list of attribute values
my @attrValues = $group->attrGet(sort @attrs);

ok( join(",",@attrValues) eq 'dudeman23,What??' );
# print "Attr Values = '".join("', '",@attrValues)."'\n";

# Get a list of datasets (should be none)
my @datasets = $group->datasets;

ok( scalar(@datasets) == 0 );

# Create another group
my $group2 = new PDL::IO::HDF5::Group( 'name'=> '/dude2', parent => $hdfobj,
				fileObj => $hdfobj);

# open the root group
my $rootGroup = new PDL::IO::HDF5::Group( 'name'=> '/', parent => $hdfobj,
					fileObj => $hdfobj);

# Get a list of groups
my @groups = $rootGroup->groups;

# print "Root group has these groups '".join(",",sort @groups)."'\n";
ok( join(",",sort @groups) eq 'dude,dude2' );


# Get a list of groups in group2 (should be none)
@groups = $group2->groups;

ok( scalar(@groups) == 0 );


# Create a dataset in the root group
my $dataset = new PDL::IO::HDF5::Dataset( 'name'=> 'data1', parent => $rootGroup,
					fileObj => $hdfobj);
					
my $pdl = sequence(5,4);


ok( $dataset->set($pdl) );
# print "pdl written = \n".$pdl."\n";


my $pdl2 = $dataset->get;
# print "pdl read = \n".$pdl2."\n";

ok( (($pdl - $pdl2)->sum) < .001 );



# Set attribute for dataset
ok( $dataset->attrSet( 'attr1' => 'dataset dudeman', 'attr2' => 'Huh What??'));

# Try Setting attr for an existing attr
ok($dataset->attrSet( 'attr1' => 'dataset dudeman23'));


# Add a attribute and then delete it
ok( $dataset->attrSet( 'dummyAttr' => 'dummyman', 
				'dummyAttr2' => 'dummyman'));
				

ok( $dataset->attrDel( 'dummyAttr', 'dummyAttr2' ));


# Get list of attributes
@attrs = $dataset->attrs;
ok( join(",",sort @attrs) eq 'attr1,attr2' );

# clean up file
unlink $filename if( -e $filename);

#print "completed\n";
