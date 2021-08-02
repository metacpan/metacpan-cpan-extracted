package PDL::IO::HDF5::Dataset;

use Carp;

use strict;
use Config;

# Global mapping variables
our ($H5T_STRING, $H5T_REFERENCE, %PDLtoHDF5internalTypeMapping, %HDF5toPDLfileMapping, %PDLtoHDF5fileMapping);

=head1 NAME

PDL::IO::HDF5::Dataset - PDL::IO::HDF5 Helper Object representing HDF5 datasets.

=head1 DESCRIPTION

This is a helper-object used by PDL::IO::HDF5 to interface with HDF5 format's dataset objects.
Information on the HDF5 Format can be found
at the HDF Group's web site at http://www.hdfgroup.org .

=head1 SYNOPSIS

See L<PDL::IO::HDF5>

=head1 MEMBER DATA

=over 1

=item ID

ID number given to the dataset by the HDF5 library

=item name

Name of the dataset. 

=item parent

Ref to parent object (group) that owns this dateset.

=item fileObj

Ref to the L<PDL::IO::HDF5> object that owns this object.


=back

=head1 METHODS

####---------------------------------------------------------

=head2 new

=for ref

PDL::IO::HDF5::Dataset Constructor - creates new object

B<Usage:>

=for usage

This object will usually be created using the calling format detailed in the L<SYNOPSIS>. The 
following syntax is used by the L<PDL::IO::HDF5> object to build the object.
   
   $a = new PDL::IO::HDF5:Dataset( name => $name, parent => $parent, 
   				fileObj => $fileObj);
	Args:
	$name				Name of the dataset
	$parent				Parent Object that owns this dataset
	$fileObj                        PDL::HDF object that owns this dateset.



=cut

sub new{

	my $type = shift;
	my %parms = @_;
	my $self = {};

	my @DataMembers = qw( name parent fileObj);
	my %DataMembers;
	@DataMembers{ @DataMembers } = @DataMembers; # hash for quick lookup
	# check for proper supplied names:
	my $varName;
	foreach $varName(keys %parms){
 		unless( defined($DataMembers{$varName})){
			carp("Error Calling ".__PACKAGE__." Constuctor\n  \'$varName\' not a valid data member\n"); 
			return undef;
		}
 		unless( defined($parms{$varName})){
			carp("Error Calling ".__PACKAGE__." Constuctor\n  \'$varName\' not supplied\n"); 
			return undef;
		}
		$self->{$varName} = $parms{$varName};
	}
	
	my $parent = $self->{parent};
	my $groupID = $parent->IDget;
	my $groupName = $parent->nameGet;
	my $name = $self->{name};
	my $datasetID;

	#####
	# Turn Error Reporting off for the following, so H5 lib doesn't complain
	#  if the group isn't found.
	PDL::IO::HDF5::H5errorOff();
	my $rc = PDL::IO::HDF5::H5Gget_objinfo($groupID, $name,1,0);
	PDL::IO::HDF5::H5errorOn();
	# See if the dataset exists:
	if(  $rc >= 0){ 
		#DataSet Exists open it:
		$datasetID = PDL::IO::HDF5::H5Dopen($groupID, $name);
		if($datasetID < 0 ){
			carp "Error Calling ".__PACKAGE__." Constuctor: Can't open existing dataset '$name'\n";
			return undef;
		}

	}
	else{  # dataset didn't exist, set datasetID = 0
		## (Have to put off opening the dataset
		### until it is written to (Must know dims, etc to create)
		$datasetID = 0;
	}
                             

	$self->{ID} = $datasetID;

	bless $self, $type;

	return $self;
}	

=head2 DESTROY

=for ref

PDL::IO::HDF5::Dataset Destructor - Closes the dataset object

B<Usage:>

=for usage

   No Usage. Automatically called
   

=cut


sub DESTROY {
  my $self = shift;
  my $datasetID = $self->{ID};
  # print "In DataSet DEstroy\n";

  if( $datasetID && (PDL::IO::HDF5::H5Dclose($self->{ID}) < 0 )){
	warn("Error closing HDF5 Dataset '".$self->{name}."' in file:group: '".$self->{filename}.":".$self->{group}."'\n");
  }

}

=head2 set

=for ref

Write data to the HDF5 dataset

B<Usage:>

=for usage

 $dataset->set($pdl, unlimited => 1);     # Write the array data in the dataset

     Options:
     unlimited     If present, the dataset is created with unlimited dimensions.

=cut


#############################################################################
# Mapping of PDL types to HDF5 types for writing to a dataset
#
#   Mapping of PDL types to what HDF5 calls them while we are dealing with them 
#   outside of the HDF5 file.
%PDLtoHDF5internalTypeMapping = (
	$PDL::Types::PDL_B	=>	PDL::IO::HDF5::H5T_NATIVE_CHAR(),
	$PDL::Types::PDL_S	=> 	PDL::IO::HDF5::H5T_NATIVE_SHORT(),
	$PDL::Types::PDL_L	=> 	PDL::IO::HDF5::H5T_NATIVE_INT(),
	$PDL::Types::PDL_LL	=> 	PDL::IO::HDF5::H5T_NATIVE_LLONG(),
        $PDL::Types::PDL_F	=>	PDL::IO::HDF5::H5T_NATIVE_FLOAT(),
	$PDL::Types::PDL_D	=>	PDL::IO::HDF5::H5T_NATIVE_DOUBLE(),
);

#   Mapping of PDL types to what types they are written to in the HDF5 file.
#   For 64 Bit machines, we might need to modify this with some smarts to determine
#   what is appropriate
my %PDLtoHDF5fileMapping;
if ( $Config{byteorder} =~ m/4321$/ ) {
    # Big endian.
    %PDLtoHDF5fileMapping = (
	$PDL::Types::PDL_B	=>	PDL::IO::HDF5::H5T_STD_I8BE(),
	$PDL::Types::PDL_S	=> 	PDL::IO::HDF5::H5T_STD_I16BE(),
	$PDL::Types::PDL_L	=> 	PDL::IO::HDF5::H5T_STD_I32BE(),
	$PDL::Types::PDL_LL	=> 	PDL::IO::HDF5::H5T_STD_I64BE(),
        $PDL::Types::PDL_F	=>	PDL::IO::HDF5::H5T_IEEE_F32BE(),
	$PDL::Types::PDL_D	=>	PDL::IO::HDF5::H5T_IEEE_F64BE(),
	);
} else {
    # Little endian.
    %PDLtoHDF5fileMapping = (
	$PDL::Types::PDL_B	=>	PDL::IO::HDF5::H5T_STD_I8LE(),
	$PDL::Types::PDL_S	=> 	PDL::IO::HDF5::H5T_STD_I16LE(),
	$PDL::Types::PDL_L	=> 	PDL::IO::HDF5::H5T_STD_I32LE(),
	$PDL::Types::PDL_LL	=> 	PDL::IO::HDF5::H5T_STD_I64LE(),
        $PDL::Types::PDL_F	=>	PDL::IO::HDF5::H5T_IEEE_F32LE(),
	$PDL::Types::PDL_D	=>	PDL::IO::HDF5::H5T_IEEE_F64LE(),
	);
}


sub set{

	my $self = shift;

	my $pdl = shift;

	my %options = @_
	    if ( scalar(@_) >= 1 );

	my $parent = $self->{parent};
	my $groupID = $parent->IDget;
	my $datasetID = $self->{ID};
	my $name = $self->{name};
	my $internalhdf5_type;  # hdf5 type that describes the way data is stored in memory
	my $hdf5Filetype;       # hdf5 type that describes the way data will be stored in the file.
	my @dims;               # hdf5 equivalent dims for the supplied PDL

	my $type = $pdl->get_datatype; # get PDL datatype
	if( $pdl->isa('PDL::Char') ){ #  Special Case for PDL::Char Objects (fixed length strings)
	
		@dims = $pdl->dims;
		my $length = shift @dims; # String length is the first dim of the PDL for PDL::Char
		# Create Null-Terminated String Type 
		$internalhdf5_type = PDL::IO::HDF5::H5Tcopy(PDL::IO::HDF5::H5T_C_S1());
		PDL::IO::HDF5::H5Tset_size($internalhdf5_type, $length ); # make legth of type eaual to strings
		$hdf5Filetype =  $internalhdf5_type; # memory and file storage will be the same type
		
		@dims = reverse(@dims);  # HDF5 stores columns/rows in reverse order than pdl

	}
	else{   # Other PDL Types


		unless( defined($PDLtoHDF5internalTypeMapping{$type}) ){
			carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
			return undef;
		}
		$internalhdf5_type = $PDLtoHDF5internalTypeMapping{$type};
	
		unless( defined($PDLtoHDF5fileMapping{$type}) ){
			carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
			return undef;
		}	
		$hdf5Filetype = $PDLtoHDF5fileMapping{$type};


		@dims = reverse($pdl->dims); # HDF5 stores columns/rows in reverse order than pdl

	}


	
	
        my $dims = PDL::IO::HDF5::packList(@dims);

	my $udims = $dims;
	if ( exists($options{'unlimited'}) ) {
	    my $udim = pack ("L*", (PDL::IO::HDF5::H5S_UNLIMITED()));
	    my $rank = scalar(@dims)*2;
	    $udims = $udim x $rank;
	}
	my $dataspaceID = PDL::IO::HDF5::H5Screate_simple(scalar(@dims), $dims , $udims);
        if( $dataspaceID < 0 ){
		carp("Can't Open Dataspace in ".__PACKAGE__.":set\n");
		return undef;
	}

	if( $datasetID == 0){  # Dataset not created yet

	    my $propertiesID;
	    if ( exists($options{'unlimited'}) ) {
		$propertiesID = PDL::IO::HDF5::H5Pcreate(PDL::IO::HDF5::H5P_DATASET_CREATE());
		if( $propertiesID < 0 ){
		    carp("Can't Open Properties in ".__PACKAGE__.":set\n");
		    return undef;
		}	    
		if ( PDL::IO::HDF5::H5Pset_chunk($propertiesID,scalar(@dims),$dims) < 0 ) {
		    carp("Error setting chunk size in ".__PACKAGE__.":set\n");
		    return undef;
		}	
		# /* Create the dataset. */
		$datasetID = PDL::IO::HDF5::H5Dcreate($groupID, $name, $hdf5Filetype, $dataspaceID, 
						      $propertiesID);
	    } else {
	       # /* Create the dataset. */
		$datasetID = PDL::IO::HDF5::H5Dcreate($groupID, $name, $hdf5Filetype, $dataspaceID, 
						      PDL::IO::HDF5::H5P_DEFAULT());
	    }
	    if( $datasetID < 0){
		carp("Can't Create Dataspace in ".__PACKAGE__.":set\n");
		return undef;
	    }
	    $self->{ID} = $datasetID;

	    if ( exists($options{'unlimited'}) ) {
		if ( PDL::IO::HDF5::H5Pclose($propertiesID) < 0 ) {
		    carp("Error closing properties in ".__PACKAGE__.":set\n");
		    return undef;
		}
	    }
	}

	# Write the actual data:
        my $data = ${$pdl->get_dataref};
	
	if( PDL::IO::HDF5::H5Dextend($datasetID,$dims) < 0 ){ 
		carp("Error extending dataset in ".__PACKAGE__.":set\n");
		return undef;
	}

	if( PDL::IO::HDF5::H5Dwrite($datasetID, $internalhdf5_type, PDL::IO::HDF5::H5S_ALL(), PDL::IO::HDF5::H5S_ALL(), PDL::IO::HDF5::H5P_DEFAULT(),
		$data) < 0 ){ 

		carp("Error Writing to dataset in ".__PACKAGE__.":set\n");
		return undef;

	}
	

	# /* Terminate access to the data space. */
	carp("Can't close Dataspace in ".__PACKAGE__.":set\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);

	return 1;

}


=head2 get

=for ref

Get data from a HDF5 dataset to a PDL

B<Usage:>

=for usage

 $pdl = $dataset->get;     # Read the Array from the HDF5 dataset, create a PDL from it
		       	   #  and put in $pdl

                           # Assuming $dataset is three dimensional
                           # with dimensions (20,100,90)

The I<get> method can also be used to obtain particular slices or hyperslabs
of the dataset array. For example, if $dataset is three dimensional with dimensions
(20,100,90) then we could do:

 $start=pdl([0,0,0]);      # We begin the slice at the very beginning
 $end=pdl([19,0,0]);       # We take the first vector of the array,
 $stride=pdl([2,1,1]);     # taking only every two values of the vector 

 $pdl = $dataset->get($start,$end,[$stride]); # Read a slice or
                           # hyperslab from the HDF5 dataset.
                           # $start, $end and optionally $stride
                           # should be PDL vectors with length the
                           # number of dimensions of the dataset.
                           # $start gives the starting coordinates
                           # in the array.
                           # $end gives the ending coordinate
                           # in the array
                           # $stride gives the steps taken from one
                           # coordinate to the next of the slice


The mapping of HDF5 datatypes in the file to PDL datatypes in memory will be according
to the following table.

 HDF5 File Type				PDL Type
 ------------------------               -----------------
 PDL::IO::HDF5::H5T_C_S1()	=>      PDL::Char Object    (Special Case for Char Strings)
 PDL::IO::HDF5::H5T_STD_I8BE()	=> 	$PDL::Types::PDL_B
 PDL::IO::HDF5::H5T_STD_I8LE()	=> 	$PDL::Types::PDL_B,
 PDL::IO::HDF5::H5T_STD_U8BE()	=> 	$PDL::Types::PDL_S,
 PDL::IO::HDF5::H5T_STD_U8LE()	=> 	$PDL::Types::PDL_S,
 PDL::IO::HDF5::H5T_STD_I16BE()	=> 	$PDL::Types::PDL_S,
 PDL::IO::HDF5::H5T_STD_I16LE()	=> 	$PDL::Types::PDL_S,
 PDL::IO::HDF5::H5T_STD_U16BE()	=> 	$PDL::Types::PDL_L,
 PDL::IO::HDF5::H5T_STD_U16LE()	=> 	$PDL::Types::PDL_L,
 PDL::IO::HDF5::H5T_STD_I32BE()	=> 	$PDL::Types::PDL_L,
 PDL::IO::HDF5::H5T_STD_I32LE()	=> 	$PDL::Types::PDL_L,
 PDL::IO::HDF5::H5T_STD_U32LE()	=> 	$PDL::Types::PDL_LL,
 PDL::IO::HDF5::H5T_STD_U32BE()	=> 	$PDL::Types::PDL_LL,
 PDL::IO::HDF5::H5T_STD_I64LE()	=> 	$PDL::Types::PDL_LL,
 PDL::IO::HDF5::H5T_STD_I64BE()	=> 	$PDL::Types::PDL_LL,
 PDL::IO::HDF5::H5T_IEEE_F32BE()=>	$PDL::Types::PDL_F,
 PDL::IO::HDF5::H5T_IEEE_F32LE()=>	$PDL::Types::PDL_F,
 PDL::IO::HDF5::H5T_IEEE_F64BE()=>	$PDL::Types::PDL_D,
 PDL::IO::HDF5::H5T_IEEE_F64LE()=>	$PDL::Types::PDL_D

For HDF5 File types not in this table, this method will attempt to
map it to the default PDL type PDL_D.

If the dataset being read is a scalar reference, the referenced dataset region will be read instead.

B<Note:>
 
Character arrays are returned as the special L<PDL::Char> fixed-length string type. For fixed-length
HDF5 string arrays, this is a direct mapping to the PDL::Char datatype. For HDF5 variable-length string
arrays, the data is converted to a fixed-length character array, with a string size equal to the maximum
size of all the strings in the array.


=cut


#############################################################################
# Mapping of HDF5 file types to PDL types
#   For 64 Bit machines, we might need to modify this with some smarts to determine
#   what is appropriate
%HDF5toPDLfileMapping = (
	 PDL::IO::HDF5::H5T_STD_I8BE()	=> 	$PDL::Types::PDL_B,
	 PDL::IO::HDF5::H5T_STD_I8LE()	=> 	$PDL::Types::PDL_B,
	 PDL::IO::HDF5::H5T_STD_U8BE()	=> 	$PDL::Types::PDL_S,
	 PDL::IO::HDF5::H5T_STD_U8LE()	=> 	$PDL::Types::PDL_S,
	 PDL::IO::HDF5::H5T_STD_I16BE()	=> 	$PDL::Types::PDL_S,
	 PDL::IO::HDF5::H5T_STD_I16LE()	=> 	$PDL::Types::PDL_S,
	 PDL::IO::HDF5::H5T_STD_U16BE()	=> 	$PDL::Types::PDL_L,
	 PDL::IO::HDF5::H5T_STD_U16LE()	=> 	$PDL::Types::PDL_L,
	 PDL::IO::HDF5::H5T_STD_I32BE()	=> 	$PDL::Types::PDL_L,
	 PDL::IO::HDF5::H5T_STD_I32LE()	=> 	$PDL::Types::PDL_L,
	 PDL::IO::HDF5::H5T_STD_U32LE()	=> 	$PDL::Types::PDL_LL,
	 PDL::IO::HDF5::H5T_STD_U32BE()	=> 	$PDL::Types::PDL_LL,
	 PDL::IO::HDF5::H5T_STD_I64LE()	=> 	$PDL::Types::PDL_LL,
	 PDL::IO::HDF5::H5T_STD_I64BE()	=> 	$PDL::Types::PDL_LL,
	 PDL::IO::HDF5::H5T_IEEE_F32BE()	=>	$PDL::Types::PDL_F,
	 PDL::IO::HDF5::H5T_IEEE_F32LE()	=>	$PDL::Types::PDL_F,
	 PDL::IO::HDF5::H5T_IEEE_F64BE()	=>	$PDL::Types::PDL_D,
	 PDL::IO::HDF5::H5T_IEEE_F64LE()	=>	$PDL::Types::PDL_D
);

$H5T_STRING    = PDL::IO::HDF5::H5T_STRING   (); #HDF5 string type
$H5T_REFERENCE = PDL::IO::HDF5::H5T_REFERENCE(); #HDF5 reference type

sub get{

	my $self = shift;
	my $start = shift;
	my $end = shift;
	my $stride = shift;

	my $pdl;

 	my $rc; # H5 library call return code

	my $parent = $self->{parent};
	my $groupID = $parent->IDget;
	my $datasetID = $self->{ID};
	my $name = $self->{name};
	my $stringSize;  		# String size, if we are retrieving a string type
	my $PDLtype;     		# PDL type that the data will be mapped to
	my $internalhdf5_type; 		# Type that represents how HDF5 will store the data in memory (after retreiving from
					#  the file)

	my $ReturnType = 'PDL';	        # Default object returned is PDL. If strings are store, then this will
					# return PDL::Char

	my $isReference = 0;            # Indicates if dataset is a reference
	my $datasetReference;           # Data set reference
	my $referencedDatasetID;        # ID of referenced dataset

	# Get the HDF5 file datatype;
        my $HDF5type = PDL::IO::HDF5::H5Dget_type($datasetID );
	unless( $HDF5type >= 0 ){
		carp "Error Calling ".__PACKAGE__."::get: Can't get HDF5 Dataset type.\n";
		return undef;
	}

	# Check for string type:
 	my $varLenString = 0; # Flag = 1 if reading variable-length string array
	if( PDL::IO::HDF5::H5Tget_class($HDF5type ) == $H5T_STRING ){  # String type

	        # Check for variable length string"
	        if( ! PDL::IO::HDF5::H5Tis_variable_str($HDF5type ) ){
	                # Not a variable length string
	                $stringSize = PDL::IO::HDF5::H5Tget_size($HDF5type);
                        unless( $stringSize >= 0 ){
                                carp "Error Calling ".__PACKAGE__."::get: Can't get HDF5 String Datatype Size.\n";
                                carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
                                return undef;
                        }
                        $internalhdf5_type =  $HDF5type; # internal storage the same as the file storage.
                }
                else{
                        # Variable-length String, set flag
                        $varLenString = 1;
                        
                        # Create variable-length type for reading from the file
                        $internalhdf5_type = PDL::IO::HDF5::H5Tcopy(PDL::IO::HDF5::H5T_C_S1() );
                        PDL::IO::HDF5::H5Tset_size( $internalhdf5_type, PDL::IO::HDF5::H5T_VARIABLE() );

                }

		$PDLtype = $PDL::Types::PDL_B; 
		$ReturnType = 'PDL::Char';	 # For strings, we return a PDL::Char

	}
	elsif ( PDL::IO::HDF5::H5Tget_class($HDF5type) == $H5T_REFERENCE ) { # Reference type

	    # Flag that dataset is a reference
	    $isReference = 1;

	    # Check that the reference dataset is a single element
	    my $dataspaceID = PDL::IO::HDF5::H5Dget_space($datasetID);
	    my $Ndims = PDL::IO::HDF5::H5Sget_simple_extent_ndims($dataspaceID);
	    if( $Ndims != 0 ){
	    	carp("Can't handle non-scalar references ".__PACKAGE__.":get\n");
	    	carp("Can't close Dataspace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
	    	return undef;
	    }	   

            # Read the reference
	    my $howBig =  PDL::IO::HDF5::H5Tget_size(PDL::IO::HDF5::H5T_STD_REF_DSETREG());
	    $datasetReference = ' ' x $howBig;
	    $rc = PDL::IO::HDF5::H5Dread($datasetID, PDL::IO::HDF5::H5T_STD_REF_DSETREG(), PDL::IO::HDF5::H5S_ALL(),
					 PDL::IO::HDF5::H5S_ALL(), 
					 PDL::IO::HDF5::H5P_DEFAULT(),
					 $datasetReference);
	    # Dereference the reference
	    $referencedDatasetID = PDL::IO::HDF5::H5Rdereference($datasetID,PDL::IO::HDF5::H5R_DATASET_REGION(),$datasetReference);

	    # Get the data type of the dereferenced object
	    $HDF5type = PDL::IO::HDF5::H5Dget_type($referencedDatasetID);
	    
	    # Map the HDF5 file datatype to a PDL datatype
	    $PDLtype = $PDL::Types::PDL_D; # Default type is double

	    my $defaultType;
	    foreach $defaultType( keys %HDF5toPDLfileMapping){
		if( PDL::IO::HDF5::H5Tequal($defaultType,$HDF5type) > 0){
		    $PDLtype = $HDF5toPDLfileMapping{$defaultType};
		    last;
		}
	    }
	    
	    
	    # Get the HDF5 internal datatype that corresponds to the PDL type
	    unless( defined($PDLtoHDF5internalTypeMapping{$PDLtype}) ){
		carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
		return undef;
	    }
	    $internalhdf5_type = $PDLtoHDF5internalTypeMapping{$PDLtype};

	}
	else{  # Normal Numeric Type
		# Map the HDF5 file datatype to a PDL datatype
		$PDLtype = $PDL::Types::PDL_D; # Default type is double
		
		my $defaultType;
		foreach $defaultType( keys %HDF5toPDLfileMapping){
			if( PDL::IO::HDF5::H5Tequal($defaultType,$HDF5type) > 0){
				$PDLtype = $HDF5toPDLfileMapping{$defaultType};
				last;
			}
		}
		
	
		# Get the HDF5 internal datatype that corresponds to the PDL type
		unless( defined($PDLtoHDF5internalTypeMapping{$PDLtype}) ){
			carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
			return undef;
		}
		$internalhdf5_type = $PDLtoHDF5internalTypeMapping{$PDLtype};
	}

	my $dataspaceID;
	if ( $isReference == 1 ) {
	    # Get the dataspace from the reference
	    $dataspaceID = PDL::IO::HDF5::H5Rget_region($datasetID,PDL::IO::HDF5::H5R_DATASET_REGION(),$datasetReference);	    
	    # Now reset the dataset ID to that of the referenced dataset for all further use
	    $datasetID = $referencedDatasetID;
	} else {
	    # Get the dataspace from the dataset itself
	    $dataspaceID = PDL::IO::HDF5::H5Dget_space($datasetID);
	}
	if( $dataspaceID < 0 ){
		carp("Can't Open Dataspace in ".__PACKAGE__.":get\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		return undef;
	}


	# Get the number of dims:
	my $Ndims = PDL::IO::HDF5::H5Sget_simple_extent_ndims($dataspaceID);
 	if( $Ndims < 0 ){
		carp("Can't Get Number of Dims in  Dataspace in ".__PACKAGE__.":get\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	}


	my @dims = ( 0..($Ndims-1)); 
	my ($mem_space,$file_space);
	if ( $isReference == 1) {
	    my @startAt = ( 0..($Ndims-1)); 
	    my @endAt = ( 0..($Ndims-1)); 
	    my $startAt = PDL::IO::HDF5::packList(@startAt);
	    my $endAt = PDL::IO::HDF5::packList(@endAt);
	    
	    my $rc = PDL::IO::HDF5::H5Sget_select_bounds($dataspaceID, $startAt, $endAt );
	    
	    if( $rc < 0 ){
		carp("Error getting number of dims in dataspace in ".__PACKAGE__.":get\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    
	    @startAt = PDL::IO::HDF5::unpackList($startAt);
	    @endAt   = PDL::IO::HDF5::unpackList($endAt);
	    for(my $i=0;$i<=$#dims;++$i) {
		$dims[$i] = $endAt[$i]-$startAt[$i]+1;
	    }
	    if (not defined $start) {
		$start  = PDL->zeros($Ndims);
		$end    = PDL->zeros($Ndims);
		$start .= PDL->pdl(@startAt);
		$end   .= PDL->pdl(@endAt);
	    } else {
		$start += PDL->pdl(@startAt);
		$end   += PDL->pdl(@startAt);
	    }
	}

	if (not defined $start) {
	    # Initialize Dims structure:
	    my $dims = PDL::IO::HDF5::packList(@dims);
	    my $dims2 = PDL::IO::HDF5::packList(@dims);
	    
	    my $rc = PDL::IO::HDF5::H5Sget_simple_extent_dims($dataspaceID, $dims, $dims2 );
	    
	    if( $rc != $Ndims){
		carp("Error getting number of dims in dataspace in ".__PACKAGE__.":get\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    
	    @dims = PDL::IO::HDF5::unpackList($dims); # get the dim sizes from the binary structure
	    
	} else {
	    if ( ($start->getndims != 1) || ($start->getdim(0) != $Ndims) ){
		carp("Wrong dimensions in start PDL in ".__PACKAGE__."\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    my $start2 = PDL::IO::HDF5::packList(reverse($start->list));
	    if (not defined $end) {
		carp("No end supplied in ".__PACKAGE__."\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    if ( ($end->getndims != 1) || ($end->getdim(0) != $Ndims) ) {
		carp("Wrong dimensions in end PDL in ".__PACKAGE__."\n") ;
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    
	    my $length2;
	    
	    if (defined $stride) {
		if ( ($stride->getndims != 1) || 
		     ($stride->getdim(0) != $Ndims) ) {
		    carp("Wrong dimensions in stride in ".__PACKAGE__."\n");
		    carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		    carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		    return undef;
		}
		@dims=reverse((($end-$start+1)/$stride)->list);
		$length2 = PDL::IO::HDF5::packList(@dims);
	    } else {
		@dims=reverse(($end-$start+1)->list);
		$length2 = PDL::IO::HDF5::packList(@dims);
		$stride=PDL::Core::ones($Ndims);
	    }
	    my $mem_dims = PDL::IO::HDF5::packList(@dims);
	    my $stride2 = PDL::IO::HDF5::packList(reverse($stride->list));
	    my $block=PDL::Core::ones($Ndims);
	    my $block2 = PDL::IO::HDF5::packList(reverse($block->list));
	    
	    # Slice the data
	    $file_space = PDL::IO::HDF5::H5Dget_space($datasetID);
	    $rc=PDL::IO::HDF5::H5Sselect_hyperslab($file_space, 0, 
						   $start2, $stride2, $length2, $block2);
	    
	    
	    if( $rc < 0 ){
		carp("Error slicing data from file in ".__PACKAGE__.":get\n");
		carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	    }
	    
	    $mem_space = PDL::IO::HDF5::H5Screate_simple($Ndims, $mem_dims, 
							 $mem_dims);
	    
	}

        # Create initial PDL null array with the proper datatype	
	$pdl = $ReturnType->null;
	$pdl->set_datatype($PDLtype);

	my @pdldims;  # dims of the PDL
	my $datatypeSize; # Size of one element of data stored
	if( defined( $stringSize )){  # Fixed-Length String types
	    
	    @pdldims = ($stringSize,reverse(@dims)); # HDF5 stores columns/rows in reverse order than pdl,
	    #  1st PDL dim is the string length (for PDL::Char)

	    $datatypeSize = PDL::howbig($pdl->get_datatype);
	}
	elsif( $varLenString ){ # Variable-length String
	      # (Variable length string arrays will be converted to fixed-length strings later)
	    @pdldims = (reverse(@dims)); 		# HDF5 stores columns/rows in reverse order than pdl
	    
	    # Variable length strings are stored as arrays of string pointers, so get that size
	    #   This will by 4 bytes on 32-bit machines, and 8 bytes on 64-bit machines.
	    $datatypeSize = PDL::IO::HDF5::bufPtrSize();
	}
	else{ # Normal Numeric types
	      # (Variable length string arrays will be converted to fixed-length strings later)
	    @pdldims = (reverse(@dims)); 		# HDF5 stores columns/rows in reverse order than pdl

	    $datatypeSize = PDL::howbig($pdl->get_datatype);
	}
	
	$pdl->setdims(\@pdldims);
	
	my $nelems = 1;
	foreach (@pdldims){ $nelems *= $_; }; # calculate the number of elements
	
	my $datasize = $nelems * $datatypeSize;
	
	# Create empty space for the data
	#   Incrementally, to get around problem on win32
	my $howBig = $datatypeSize;
	my $data = ' ' x $howBig;
	foreach my $dim(@pdldims){
	    $data = $data x $dim;
	}
	# Read the data:
	if (not defined $start) {
	    $rc = PDL::IO::HDF5::H5Dread($datasetID, $internalhdf5_type, PDL::IO::HDF5::H5S_ALL(), PDL::IO::HDF5::H5S_ALL(), 
					 PDL::IO::HDF5::H5P_DEFAULT(),
					 $data);
	} else {

	    $rc = PDL::IO::HDF5::H5Dread($datasetID, $internalhdf5_type,
					 $mem_space, $file_space, 
					 PDL::IO::HDF5::H5P_DEFAULT(),
					 $data);
	}

	
	if( $rc < 0 ){
	    carp("Error reading data from file in ".__PACKAGE__.":get\n");
	    carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
	    carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	}
	
	if( $varLenString ){ 
	        # Convert variable-length string to fixed-length string, to be compatible with the PDL::Char type
	        my $maxsize = PDL::IO::HDF5::findMaxVarLenSize($data, $nelems);

                # Create empty space for the fixed-length data
                #   Incrementally, to get around problem on win32
                my $howBig = $maxsize + 1; # Adding one to include the null string terminator
                my $fixeddata = ' ' x $howBig;
                foreach my $dim(@pdldims){
                    $fixeddata = $fixeddata x $dim;
                }
                
                PDL::IO::HDF5::copyVarLenToFixed($data, $fixeddata, $nelems, $maxsize);
                
                # Reclaim data from HDF5 system (HDF5 allocates memory when it reads variable-length strings)
                $rc = PDL::IO::HDF5::H5Dvlen_reclaim ($internalhdf5_type, $dataspaceID, PDL::IO::HDF5::H5P_DEFAULT(), $data);
                if( $rc < 0 ){
                    carp("Error reclaiming memeory while reading data from file in ".__PACKAGE__.":get\n");
                    carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
                    carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
                        return undef;
                }

                # Adjust for fixed-length PDL creation
                $data = $fixeddata;
                unshift @pdldims, ($maxsize+1);
        }
	
	# Setup the PDL with the proper dimensions and data
	$pdl->setdims(\@pdldims);

	# Update the PDL data with the data read from the file
	${$pdl->get_dataref()} = $data;
	$pdl->upd_data();


	# /* Terminate access to the data space. */
	carp("Can't close Dataspace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);

	# /* Terminate access to the data type. */
	carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
	return $pdl;

}


=head2 dims

=for ref

Get the dims for a HDF5 dataset. For example, a 3 x 4 array would return a perl array
(3,4);

B<Usage:>

=for usage

 @pdl = $dataset->dims;    # Get an array of dims. 

=cut


sub dims{

	my $self = shift;

	my $parent = $self->{parent};
	my $groupID = $parent->IDget;
	my $datasetID = $self->{ID};
	my $name = $self->{name};


	my $dataspaceID = PDL::IO::HDF5::H5Dget_space($datasetID);
	if( $dataspaceID < 0 ){
		carp("Can't Open Dataspace in ".__PACKAGE__.":get\n");
		return undef;
	}


	# Get the number of dims:
	my $Ndims = PDL::IO::HDF5::H5Sget_simple_extent_ndims($dataspaceID);
 	if( $Ndims < 0 ){
		carp("Can't Get Number of Dims in  Dataspace in ".__PACKAGE__.":get\n");
		return undef;
	}


	# Initialize Dims structure:
	my @dims = ( 0..($Ndims-1)); 
        my $dims = PDL::IO::HDF5::packList(@dims);
	my $dims2 = PDL::IO::HDF5::packList(@dims);

        my $rc = PDL::IO::HDF5::H5Sget_simple_extent_dims($dataspaceID, $dims, $dims2 );

	if( $rc != $Ndims){
		carp("Error getting number of dims in dataspace in ".__PACKAGE__.":get\n");
		carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		return undef;
	}

	@dims = PDL::IO::HDF5::unpackList($dims); # get the dim sizes from the binary structure

	return reverse @dims;  # return dims in the order that PDL will store them
}

=head2 attrSet

=for ref

Set the value of an attribute(s)

Attribute types supported are null-terminated strings and PDL matrices

B<Usage:>

=for usage

   $dataset->attrSet( 'attr1' => 'attr1Value',
   		    'attr2' => 'attr2 value', 
                    'attr3' => $pdl,
		    .
		    .
		    .
		   );

Returns undef on failure, 1 on success.

=cut

sub attrSet {
	my $self = shift;

	my %attrs = @_; # get atribute hash
	
	my $datasetID = $self->{ID};

	unless( $datasetID){ # Error checking
		carp("Can't Set Attribute for empty dataset. Try writing some data to it first:\n");
		carp("    in file:group: '".$self->{filename}.":".$self->{group}."'\n");
		return undef;
	}
	
	my($key,$value);

	my $typeID; # id used for attribute
	my $dataspaceID; # id used for the attribute dataspace
	
	my $attrID;
	foreach $key( sort keys %attrs){
		
		$value = $attrs{$key};
		
	    if (ref($value) =~ /^PDL/) {
		
		my $internalhdf5_type;  # hdf5 type that describes the way data is stored in memory

		my @dims;               # hdf5 equivalent dims for the supplied PDL
		
		my $type = $value->get_datatype; # get PDL datatype

		if( $value->isa('PDL::Char') ){ #  Special Case for PDL::Char Objects (fixed length strings)
		    
		    @dims = $value->dims;

		    my $length = shift @dims; # String length is the first dim of the PDL for PDL::Char

		    # Create Null-Terminated String Type 
		    $internalhdf5_type = PDL::IO::HDF5::H5Tcopy(PDL::IO::HDF5::H5T_C_S1());
		    PDL::IO::HDF5::H5Tset_size($internalhdf5_type, $length ); # make legth of type eaual to strings
		    $typeID =  $internalhdf5_type; # memory and file storage will be the same type
		    @dims = reverse(@dims);  # HDF5 stores columns/rows in reverse order than pdl
		    
		} else {   # Other PDL Types
		    
		    
		    unless( defined($PDLtoHDF5internalTypeMapping{$type}) ){
			carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
			return undef;
		    }
		    $internalhdf5_type = $PDLtoHDF5internalTypeMapping{$type};

		    $typeID = PDL::IO::HDF5::H5Tcopy($internalhdf5_type);

		    @dims = reverse($value->dims); # HDF5 stores columns/rows in reverse order than pdl
		    
		}
		
		my $dims = PDL::IO::HDF5::packList(@dims);
		
		
		$value = ${$value->get_dataref};
		$dataspaceID = PDL::IO::HDF5::H5Screate_simple(scalar(@dims), $dims , $dims);
		if( $dataspaceID < 0 ){
		    carp("Can't Open Dataspace in ".__PACKAGE__.":set\n");
		    return undef;
		}
		
	    } else {
		# Create Null-Terminated String Type 
		$typeID = PDL::IO::HDF5::H5Tcopy(PDL::IO::HDF5::H5T_C_S1());
		PDL::IO::HDF5::H5Tset_size($typeID, length($value) || 1 ); # make legth of type eaual to length of $value or 1 if zero
		$dataspaceID = PDL::IO::HDF5::H5Screate_simple(0, 0, 0);
	    }

		#Note: If a attr already exists, then it will be deleted an re-written
		# Delete the attribute first
		PDL::IO::HDF5::H5errorOff();  # keep h5 lib from complaining
		PDL::IO::HDF5::H5Adelete($datasetID, $key);
		PDL::IO::HDF5::H5errorOn();

		
		$attrID = PDL::IO::HDF5::H5Acreate($datasetID, $key, $typeID, $dataspaceID, PDL::IO::HDF5::H5P_DEFAULT());

		if($attrID < 0 ){
			carp "Error in ".__PACKAGE__." attrSet; Can't create attribute '$key'\n";

			PDL::IO::HDF5::H5Sclose($dataspaceID);
			PDL::IO::HDF5::H5Tclose($typeID); # Cleanup
			return undef;
		}
		
		# Write the attribute data.
		if( PDL::IO::HDF5::H5Awrite($attrID, $typeID, $value) < 0){
			carp "Error in ".__PACKAGE__." attrSet; Can't write attribute '$key'\n";
			PDL::IO::HDF5::H5Aclose($attrID);
			PDL::IO::HDF5::H5Sclose($dataspaceID);
			PDL::IO::HDF5::H5Tclose($typeID); # Cleanup
			return undef;
		}
		
		# Cleanup
		PDL::IO::HDF5::H5Aclose($attrID);
		PDL::IO::HDF5::H5Sclose($dataspaceID);
		PDL::IO::HDF5::H5Tclose($typeID);

			
	}
	# Clear-out the attribute index, it is no longer valid with the updates
	#  we just made.
	$self->{fileObj}->clearAttrIndex;

	return 1;
  
}

=head2 attrDel

=for ref

Delete attribute(s)

B<Usage:>

=for usage

 $dataset->attrDel( 'attr1', 
      		    'attr2',
		    .
		    .
		    .
		   );

Returns undef on failure, 1 on success.

=cut

sub attrDel {
	my $self = shift;

	my @attrs = @_; # get atribute names
	
	my $datasetID = $self->{ID};

	my $attr;
	my $rc; #Return code returned by H5Adelete
	foreach $attr( @attrs ){
		

		# Note: We don't consider errors here as cause for aborting, we just
		#  complain using carp
		if( PDL::IO::HDF5::H5Adelete($datasetID, $attr) < 0){
			carp "Error in ".__PACKAGE__." attrDel; Error Deleting attribute '$attr'\n";
		}
		
	}
	# Clear-out the attribute index, it is no longer valid with the updates
	#  we just made.
	$self->{fileObj}->clearAttrIndex;

	return 1;
  
}


=head2 attrs

=for ref

Get a list of all attribute names associated with a dataset


B<Usage:>

=for usage

   @attrs = $dataset->attrs;


=cut

sub attrs {
	my $self = shift;

	my $datasetID = $self->{ID};
	
	my $defaultMaxSize = 256; # default max size of a attribute name

	my $noAttr = PDL::IO::HDF5::H5Aget_num_attrs($datasetID); # get the number of attributes

	my $attrIndex = 0; # attribute Index

	my @attrNames = ();
	my $attributeID;
	my $attrNameSize; # size of the attribute name
	my $attrName;     # attribute name

	# Go thru each attribute and get the name
	for( $attrIndex = 0; $attrIndex < $noAttr; $attrIndex++){

		$attributeID = PDL::IO::HDF5::H5Aopen_idx($datasetID, $attrIndex );

		if( $attributeID < 0){
			carp "Error in ".__PACKAGE__." attrs; Error Opening attribute number $attrIndex\n";
			next;
		}

	      	#init attrname to 256 length string (Maybe this not necessary with
		#  the typemap)
		$attrName = ' ' x 256;
		
		# Get the name
		$attrNameSize = PDL::IO::HDF5::H5Aget_name($attributeID, 256, $attrName ); 

		# If the name is greater than 256, try again with the proper size:
		if( $attrNameSize > 256 ){
			$attrName = ' ' x $attrNameSize;
			$attrNameSize = PDL::IO::HDF5::H5Aget_name($attributeID, $attrNameSize, $attrName ); 

		}

		push @attrNames, $attrName;

		# Close the attr:
		PDL::IO::HDF5::H5Aclose($attributeID);
	}


	
	return @attrNames;
  
}

=head2 attrGet

=for ref

Get the value of an attribute(s)

Currently the attribute types supported are null-terminated strings
and PDLs.

B<Usage:>

=for usage

   my @attrs = $dataset->attrGet( 'attr1', 'attr2');


=cut

sub attrGet {
	my $self = shift;

	my @attrs = @_; # get atribute array
	
	my $datasetID = $self->{ID};
	
	my($attrName,$attrValue);

	my @attrValues; #return array
	
	my $typeID; # id used for attribute
	my $dataspaceID; # id used for the attribute dataspace

	my $attrID;
	my $stringSize;
	my $Ndims;
	foreach $attrName( @attrs){
	    undef($stringSize);		
		$attrValue = undef;

		# Open the Attribute
		$attrID = PDL::IO::HDF5::H5Aopen_name($datasetID, $attrName );
		unless( $attrID >= 0){
			carp "Error Calling ".__PACKAGE__."::attrget: Can't open HDF5 Attribute name '$attrName'.\n";
			next;
		}			
		 
		# Open the data-space
		$dataspaceID = PDL::IO::HDF5::H5Aget_space($attrID);
		if( $dataspaceID < 0 ){
			carp("Can't Open Dataspace for Attribute name '$attrName' in  ".__PACKAGE__."::attrget\n");
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}

		# Check to see if the dataspace is simple
		if( PDL::IO::HDF5::H5Sis_simple($dataspaceID) < 0 ){
			carp("Warning: Non-Simple Dataspace for Attribute name '$attrName' ".__PACKAGE__."::attrget\n");
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}


		# Get the number of dims:
		$Ndims = PDL::IO::HDF5::H5Sget_simple_extent_ndims($dataspaceID);

		unless( $Ndims >= 0){
			if( $Ndims < 0 ){
				carp("Warning: Can't Get Number of Dims in Attribute name '$attrName' Dataspace in ".__PACKAGE__.":get\n");
			}
			#if( $Ndims > 0 ){
			#	carp("Warning: Non-Scalar Dataspace for Attribute name '$attrName' Dataspace in ".__PACKAGE__.":get\n");
			#}			
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}

		my $HDF5type;
		
		if ($Ndims == 0) {
		    # If it is a scalar we do this
		# Get the HDF5 dataset datatype;
		    $HDF5type = PDL::IO::HDF5::H5Aget_type($attrID );

		unless( $HDF5type >= 0 ){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't get HDF5 Dataset type in Attribute name '$attrName'.\n";
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}
		
		# Get the size so we can allocate space for it
		my $size = PDL::IO::HDF5::H5Tget_size($HDF5type);
		unless( $size){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't get HDF5 Dataset type size in Attribute name '$attrName'.\n";
			carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}
		
		#init attr value to the length of the type
		my $data = ' ' x ($size);
		    my $PDLtype;
		    my $ReturnType;
		    my $internalhdf5_type;
		if( PDL::IO::HDF5::H5Tget_class($HDF5type ) == PDL::IO::HDF5::H5T_STRING() ){  # String type
		    $PDLtype = $PDL::Types::PDL_B; 
		    $internalhdf5_type =  $HDF5type; # internal storage the same as the file storage.
		    $ReturnType = 'PDL::Char';	 # For strings, we return a PDL::Char
		    $stringSize = PDL::IO::HDF5::H5Tget_size($HDF5type);
		    unless( $stringSize >= 0 ){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't get HDF5 String Datatype Size.\n";
			carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			return undef;
		    }
		}
		else{  # Normal Numeric Type
		    # Map the HDF5 file datatype to a PDL datatype
		    $PDLtype = $PDL::Types::PDL_D; # Default type is double
		    $ReturnType = 'PDL';

		    my $defaultType;
		    foreach $defaultType( keys %HDF5toPDLfileMapping){
			if( PDL::IO::HDF5::H5Tequal($defaultType,$HDF5type) > 0){
			    $PDLtype = $HDF5toPDLfileMapping{$defaultType};
			    last;
			}
		    }
		    
		    # Get the HDF5 internal datatype that corresponds to the PDL type
		    unless( defined($PDLtoHDF5internalTypeMapping{$PDLtype}) ){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't map PDL type to HDF5 datatype\n";
			return undef;
		    }
		    $internalhdf5_type = $PDLtoHDF5internalTypeMapping{$PDLtype};
		}

		if( PDL::IO::HDF5::H5Aread($attrID, $internalhdf5_type, $data) < 0 ){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't read Attribute Value for Attribute name '$attrName'.\n";
			carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		}			
		$attrValue = $ReturnType->null;
		$attrValue->set_datatype($PDLtype);
		    my @pdldims;
		    if( defined( $stringSize )){  # String types
			@pdldims = ( $stringSize );
		    } else {	    
			@pdldims = ( 1 );
		    }
		    $attrValue->setdims(\@pdldims);
		# Update the PDL data with the data read from the file
		${$attrValue->get_dataref()} = $data;
		$attrValue->upd_data();
		
		    # End of scalar option
		} else {
		    # This is a PDL
		    # Get the HDF5 dataset datatype;
		    $HDF5type = PDL::IO::HDF5::H5Aget_type($attrID );

		    unless( $HDF5type >= 0 ){
			carp "Error Calling ".__PACKAGE__."::attrGet: Can't get HDF5 Dataset type in Attribute name '$attrName'.\n";
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			next;
		    }
		    


#*********************************************************


		    my $stringSize;
		    my $PDLtype;
		    my $internalhdf5_type;
		    my $typeID;
		    my $ReturnType = 'PDL';	        # Default object returned is PDL. If strings are store, then this will
		    # return PDL::Char
		    

		    # Check for string type:
		    my $varLenString = 0; # Flag = 1 if reading variable-length string array
		    if( PDL::IO::HDF5::H5Tget_class($HDF5type ) == $H5T_STRING ){  # String type
			
                        # Check for variable length string"
                        if( ! PDL::IO::HDF5::H5Tis_variable_str($HDF5type ) ){
                                # Not a variable length string
                                $stringSize = PDL::IO::HDF5::H5Tget_size($HDF5type);
                                unless( $stringSize >= 0 ){
                                    carp "Error Calling ".__PACKAGE__."::get: Can't get HDF5 String Datatype Size.\n";
                                    carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
                                    carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
                                    carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
                                    return undef;
                                }
                                $internalhdf5_type =  $HDF5type; # internal storage the same as the file storage.
                        }
                        else{
                                # Variable-length String, set flag
                                $varLenString = 1;
                                
                                # Create variable-length type for reading from the file
                                $internalhdf5_type = PDL::IO::HDF5::H5Tcopy(PDL::IO::HDF5::H5T_C_S1() );
                                PDL::IO::HDF5::H5Tset_size( $internalhdf5_type, PDL::IO::HDF5::H5T_VARIABLE() );
        
                        }
			
			$PDLtype = $PDL::Types::PDL_B; 
			$internalhdf5_type =  $HDF5type; # internal storage the same as the file storage.
			$typeID=$HDF5type;
			$ReturnType = 'PDL::Char';	 # For strings, we return a PDL::Char
			
		    }
		    else{  # Normal Numeric Type
			# Map the HDF5 file datatype to a PDL datatype
			$PDLtype = $PDL::Types::PDL_D; # Default type is double
			
			my $defaultType;
			foreach $defaultType( keys %HDF5toPDLfileMapping){
			    if( PDL::IO::HDF5::H5Tequal($defaultType,$HDF5type) > 0){
				$PDLtype = $HDF5toPDLfileMapping{$defaultType};
				last;
			    }
			}
	
			# Get the HDF5 internal datatype that corresponds to the PDL type
			unless( defined($PDLtoHDF5internalTypeMapping{$PDLtype}) ){
			    carp "Error Calling ".__PACKAGE__."::set: Can't map PDL type to HDF5 datatype\n";
			    carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			    carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			    carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			    return undef;
			}
			$internalhdf5_type = $PDLtoHDF5internalTypeMapping{$PDLtype};
			#$internalhdf5_type =  $HDF5type; # internal storage the same as the file storage.
			#$typeID = PDL::IO::HDF5::H5Tcopy($internalhdf5_type);
			$typeID = $internalhdf5_type;
		    } # End of String or Numeric type

		    # Initialize Dims structure:
		    my @dims = ( 0..($Ndims-1)); 
		    my $dims = PDL::IO::HDF5::packList(@dims);
		    my $dims2 = PDL::IO::HDF5::packList(@dims);

		    my $rc = PDL::IO::HDF5::H5Sget_simple_extent_dims($dataspaceID, $dims, $dims2 );

		    if( $rc != $Ndims){
			carp("Error getting number of dims in dataspace in ".__PACKAGE__.":get\n");
			carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			return undef;
		    }

		    @dims = PDL::IO::HDF5::unpackList($dims); # get the dim sizes from the binary structure
		    
		    # Create initial PDL null array with the proper datatype	
		    $attrValue = $ReturnType->null;
		    $attrValue->set_datatype($PDLtype);
		    my @pdldims;  # dims of the PDL
		    my $datatypeSize; # Size of one element of data stored
		    if( defined( $stringSize )){  # Fixed-Length String types
		
			@pdldims = ($stringSize,reverse(@dims)); # HDF5 stores columns/rows in reverse order than pdl,
			#  1st PDL dim is the string length (for PDL::Char)

			$datatypeSize = PDL::howbig($attrValue->get_datatype);
		    }
		    elsif(  $varLenString ){ # Variable-length String
                              # (Variable length string arrays will be converted to fixed-length strings later)
                            @pdldims = (reverse(@dims)); 		# HDF5 stores columns/rows in reverse order than pdl
                            
                            # Variable length strings are stored as arrays of string pointers, so get that size
                            #   This will by 4 bytes on 32-bit machines, and 8 bytes on 64-bit machines.
                            $datatypeSize = PDL::IO::HDF5::bufPtrSize();
                    }
		    else{ # Normal Numeric types
			@pdldims = (reverse(@dims)); 		# HDF5 stores columns/rows in reverse order than pdl,

                        $datatypeSize = PDL::howbig($attrValue->get_datatype);

		    }
		    
		    $attrValue->setdims(\@pdldims);
		    
		    my $nelems = 1;
		    foreach (@pdldims){ $nelems *= $_; }; # calculate the number of elements

		    my $datasize = $nelems * $datatypeSize;
		    
		    # Create empty space for the data
		    #   Incrementally, to get around problem on win32
		    my $howBig = $datatypeSize;
		    my $data = ' ' x $howBig;
		    foreach my $dim(@pdldims){
		   	$data = $data x $dim;
		    }

		    # Read the data:
		    $rc = PDL::IO::HDF5::H5Aread($attrID,$internalhdf5_type,$data);
		    
		    if( $rc < 0 ){
			carp("Error reading data from file in ".__PACKAGE__.":get\n");
			carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
			carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
			carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);
			return undef;
		    }

                    if( $varLenString ){ 
                        # Convert variable-length string to fixed-length string, to be compatible with the PDL::Char type
                        my $maxsize = PDL::IO::HDF5::findMaxVarLenSize($data, $nelems);
        
                        # Create empty space for the fixed-length data
                        #   Incrementally, to get around problem on win32
                        my $howBig = $maxsize + 1; # Adding one to include the null string terminator
                        my $fixeddata = ' ' x $howBig;
                        foreach my $dim(@pdldims){
                            $fixeddata = $fixeddata x $dim;
                        }
                        
                        PDL::IO::HDF5::copyVarLenToFixed($data, $fixeddata, $nelems, $maxsize);
                        
                        # Reclaim data from HDF5 system (HDF5 allocates memory when it reads variable-length strings)
                        $rc = PDL::IO::HDF5::H5Dvlen_reclaim ($internalhdf5_type, $dataspaceID, PDL::IO::HDF5::H5P_DEFAULT(), $data);
                        if( $rc < 0 ){
                            carp("Error reclaiming memeory while reading data from file in ".__PACKAGE__.":get\n");
                            carp("Can't close Datatype in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
                            carp("Can't close DataSpace in ".__PACKAGE__.":get\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
                                return undef;
                        }
        
                        # Adjust for fixed-length PDL creation
                        $data = $fixeddata;
                        unshift @pdldims, ($maxsize+1);
                    }

		    # Setup the PDL with the proper dimensions and data
                    $attrValue->setdims(\@pdldims);
		    ${$attrValue->get_dataref()} = $data;
		    $attrValue->upd_data();
		    

#************************************************


		} # End of PDL option

		# Cleanup
		carp("Can't close Datatype in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Tclose($HDF5type) < 0);
		carp("Can't close DataSpace in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Sclose($dataspaceID) < 0);
		carp("Can't close Attribute in ".__PACKAGE__.":attrGet\n") if( PDL::IO::HDF5::H5Aclose($attrID) < 0);


	}
	continue{
	    if ( $Ndims == 0 ) {
                if (defined($stringSize)) {
                    push @attrValues, $attrValue->atstr(0);
                } else {
                    push @attrValues, $attrValue->index(0);
                }
            } else {
                push @attrValues, $attrValue;
            }
	}

	return @attrValues;

}

=head2 IDget

=for ref

Returns the HDF5 library ID for this object

B<Usage:>

=for usage

 my $ID = $dataSetObj->IDget;

=cut

sub IDget{

	my $self = shift;
	
	return $self->{ID};
		
}

=head2 nameGet

=for ref

Returns the HDF5 Dataset Name for this object. 

B<Usage:>

=for usage

 my $name = $datasetObj->nameGet;

=cut

sub nameGet{

	my $self = shift;
	
	return $self->{name};
		
}


1;

