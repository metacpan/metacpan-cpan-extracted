# Script to test the attribute index functionality of the PDL::IO::HDF5 Class

use strict;
use warnings;
use PDL;
use PDL::Char;
use PDL::IO::HDF5;

use Data::Dumper;

use Test::More;

# New File Check:
my $filename = "total.hdf5";

ok(my $hdfobj = new PDL::IO::HDF5($filename));

# It is normally a no-no to call a internal method, but we
#  are just testing here:
$hdfobj->_buildAttrIndex;

my $result = recursiveDump($hdfobj->{attrIndex});

my $baseline = 
q!{
    / =>     {
        attr1 => dudeman23,
        attr2 => What??,
    }
    /dude2 =>     {
        attr1 => dudeman23,
        attr2 => What??,
    }
    /mygroup =>     {
        attr1 => dudeman23,
        attr2 => What??,
    }
    /mygroup/subgroup =>     {
        attr1 => dudeman23,
        attr2 => What??,
    }
}
!;

is($result, $baseline);

# die;

my @values = $hdfobj->allAttrValues('attr1');

$baseline = 
q![
    dudeman23,
    dudeman23,
    dudeman23,
    dudeman23,
]
!;

$result = recursiveDump(\@values);
is($result, $baseline);

@values = $hdfobj->allAttrValues('attr1','attr2');
$baseline = 
q![
    [
        dudeman23,
        What??,
    ]
    [
        dudeman23,
        What??,
    ]
    [
        dudeman23,
        What??,
    ]
    [
        dudeman23,
        What??,
    ]
]
!;

$result = recursiveDump(\@values);
is($result, $baseline);

my @names = $hdfobj->allAttrNames;

$baseline = 
q![
    attr1,
    attr2,
]
!;

$result = recursiveDump(\@names);
is($result, $baseline);

# Test building the groupIndex
$hdfobj->_buildGroupIndex('attr1','attr2');
$hdfobj->_buildGroupIndex('attr2');
$hdfobj->_buildGroupIndex('attr1','attr3');

$baseline = 
"{
    attr1$;attr2 =>     {
        dudeman23$;What?? =>         [
            /,
            /dude2,
            /mygroup,
            /mygroup/subgroup,
        ]
    }
    attr1$;attr3 =>     {
        dudeman23$;_undef_ =>         [
            /,
            /dude2,
            /mygroup,
            /mygroup/subgroup,
        ]
    }
    attr2 =>     {
        What?? =>         [
            /,
            /dude2,
            /mygroup,
            /mygroup/subgroup,
        ]
    }
}
";

$result = recursiveDump($hdfobj->{groupIndex});
is($result, $baseline);

my @groups = $hdfobj->getGroupsByAttr( 'attr1'  => 'dudeman23',
					'attr2' => 'What??');
$baseline = 
q![
    /,
    /dude2,
    /mygroup,
    /mygroup/subgroup,
]
!;
$result = recursiveDump(\@groups);
is($result, $baseline);

# clean up file
unlink $filename if( -e $filename);

done_testing;

# Dump of recursive array/hash.
# We Could use Data:Dumper for this but it doesn't 
#  order the keys, which causes problems 
#  in regression testing on different platforms
sub recursiveDump{
	my ($ref, $level) = @_;
	
	$level = 1 unless( defined($level));
	
	my $returnString; # String to return
	
	my $levelspace = '    ';  # Space used to indent
	
	my $indent = $levelspace x $level;
	my $unindent = $levelspace x ($level-1) ;
	
	my $displayedData = $ref;
	
	my $arrayFlag = 0;
	my @sortedKeys;
	
	 if( ref $ref eq 'ARRAY'){  # arrays are converted to hashes with indexes numbers
				    # as keys for display
		$displayedData = {};
		@$displayedData{0..$#$ref} = @$ref;
		
		$returnString = $unindent."[\n";
		$arrayFlag = 1;
		@sortedKeys = (0..$#$ref);
	 }
	 else{
		$returnString = $unindent."{\n";	
		@sortedKeys = sort keys %$displayedData;

	}

	 my $value;
	 foreach my $key(@sortedKeys){
	 	
		$value = $displayedData->{$key};
		
		if( ref( $value) ){
			$returnString .= $indent.$key." => " unless( $arrayFlag); # dumping hash Ref
			$returnString .= recursiveDump($value,$level+1);
		}
		else{
			$returnString .= $indent.$value.",\n" if( $arrayFlag); # dumping array Ref
			$returnString .= $indent.$key.' => '.$value.",\n" unless( $arrayFlag); # dumping hash Ref
			
		}
		
	}
	
	$returnString .= $unindent."}\n" unless($arrayFlag); # Dumping hash ref
	$returnString .= $unindent."]\n" if($arrayFlag); # Dumping aray ref
		
	$returnString;
}
