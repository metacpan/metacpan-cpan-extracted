#
# GENERATED WITH PDL::PP from netcdf.pd! Don't modify!
#
package PDL::NetCDF;

our @EXPORT_OK = qw();
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '4.25';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::NetCDF $VERSION;








#line 14 "netcdf.pd"

=head1 NAME

PDL::NetCDF - Object-oriented interface between NetCDF files and PDL objects.

Perl extension to allow interface to NetCDF portable
binary gridded files via PDL objects.

=head1 SYNOPSIS

  use PDL;
  use PDL::NetCDF;
  use PDL::Char;

  my $ncobj = PDL::NetCDF->new ("test.nc", {REVERSE_DIMS => 1, PDL_BAD => 1});  # New file
  my $pdl = pdl [[1, 2, 3], [4, 5, 6]];

  # Specify variable name to put PDL in, plus names of the dimensions.  Dimension         
  # lengths are taken from the PDL, in this case, dim1 = 2 and dim2 = 3.      
  $ncobj->put ('var1', ['dim1', 'dim2'], $pdl);
  # or for netcdf4 files
  # $ncobj->put ('var1', ['dim1', 'dim2'], $pdl, {DEFLATE => 9, _FillValue => -999});

  # get the deflate level (for any fileformat)
  my ($deflate, $shuffle) = $ncobj->getDeflateShuffle('var1');

  # $pdlout = [[1, 2, 3], [4, 5, 6]]
  my $pdlout = $ncobj->get ('var1');

  # Store textual NetCDF arrays using perl strings:  (This is a bit primitive, but works)
  my $str = "Station1  Station2  Station3  ";
  $obj->puttext('textvar', ['n_station', 'n_string'], [3,10], $str);
  my $outstr = $obj->gettext('textvar');
  # $outstr = "Station1  Station2  Station3  "

  # Now textual NetCDF arrays can be stored with PDL::Char style PDLs.  This is much
  # more natural and flexible than the above method.
  $str = PDL::Char->new (['Station1', 'Station2', 'Station3']);
  $obj->put ('stations', ['dim_station', 'dim_charlen'], $str);
  $outstr = $obj->get('stations');
  print $outstr;
  # Prints: ['Station1', 'Station2', 'Station3']
  # For more info on PDL::Char variables see PDL::Char(3), or perldoc PDL::Char

  # $dim1size = 2
  my $dim1size = $ncobj->dimsize('dim1');

  # A slice of the netCDF variable.
  # [0,0] is the starting point, [1,2] is the count.
  # $slice = [1,2]
  my $slice  = $ncobj->get ('var1', [0,0], [1,2]);

  # Attach a double attribute of size 3 to var1
  $ncobj->putatt (double([1,2,3]), 'double_attribute', 'var1');

  # $attr1 = [1,2,3]
  my $attr1 = $ncobj->getatt ('double_attribute', 'var1');

  # $type = PDL::double
  my $type = $ncobj->getvariabletype('var1');

  # Write a textual, global attribute.  'attr_name' is the attribute name.
  $ncobj->putatt ('The text of the global attribute', 'attr_name');          

  # $attr2 = 'The text of the global attribute'
  my $attr2 = $ncobj->getatt ('attr_name');

  # Close the netCDF file.  The file is also automatically closed in a DESTROY block
  # when it passes out of scope.  This just makes is explicit.
  $ncobj->close;

For (much) more information on NetCDF, see 

http://www.unidata.ucar.edu/packages/netcdf/index.html 

Also see the test file, test.pl in this distribution for some working examples.

=head1 DESCRIPTION

This is the PDL interface to the Unidata NetCDF library.  It uses the
netCDF version 3 library to make a subset of netCDF functionality
available to PDL users in a clean, object-oriented interface.

Another NetCDF perl interface, which allows access to the entire range
of netCDF functionality (but in a non-object-oriented
style which uses perl arrays instead of PDLs) is available through Unidata at
http://www.unidata.ucar.edu/packages/netcdf/index.html).

The NetCDF standard allows N-dimensional binary data to be efficiently
stored, annotated and exchanged between many platforms.

When one creates a new netCDF object, this object is associated with one
netCDF file.  

=head1 FUNCTIONS

=head2 isNetcdf4

=for ref

Check if compiled against netcdf4

=for usage

Arguments: none

=for example

  if (PDL::NetCDF::isNetcdf4) {
  	# open netcdf4 file
  }

=head2 defaultFormat

=for ref

Get or change the default format when creating a netcdf-file.
This can be overwritten by the NC_FORMAT option for new. Possible
values are: PDL::NetCDF::NC_FORMAT_CLASSIC, PDL::NetCDF::NC_FORMAT_64BIT,
PDL::NetCDF::NC_FORMAT_NETCDF4, PDL::NetCDF::NC_FORMAT_NETCDF4_CLASSIC 

=for usage

 Arguments:
 1) new format (constant)
 Return:
 old format as one of the NC_FORMAT_* constants

=head2 new

=for ref

Create an object representing a netCDF file.

=for usage      	

 Arguments:  
 1) The name of the file.
 2) optional:  A hashref containing options.  Currently defined are:
    TEMPLATE:
    An existing netCDF object for a file with
    identical layout.  This allows one to read in many similar netCDF
    files without incurring the overhead of reading in all variable
    and dimension names and IDs each time.  Caution:  Undefined
    weirdness may occur if you pass the netCDF object from a dissimilar
    file!
    MODE:
    use sysopen file-opening arguments, O_RDONLY, O_RDWR, O_CREAT, O_EXCL
    when used, this will overwrite the '>file.nc' type of opening
    see L<perlopentut> for usage of O_RDONLY...
    REVERSE_DIMS:
    this will turn the order of the dimension-names of
    netcdf-files. Even with this option the 'put' function will write
    variables in FORTRAN order (as before) and will reverse the
    dimension names so they fit this order.  With this option, the
    'putslice' function will write variables in the same way as 'put'.
    You should use this option if your planning to work with other
    netcdf-programs (ncview, NCL) or if you are planning to combine
    putslice and slice.  You should _not_ use this option, if you need
    compatibility to older versions of PDL::NetCDF.
    NC_FORMAT:
    set the file format for a new netcdf file, see defaultFormat()
    SLOW_CHAR_FETCH:
    If this option is set, then a 'get' into a PDL::Char will be done
    one string at a time instead of all text data at once.  This
    is necessary if there are NULLs (hex 0) values embedded in the string
    arrays.  This takes longer, but gives the correct results.  If
    the fetch of a string array yields only the first element, try setting
    this option.
    PDL_BAD:
    _FillValue's or missing_values are translated to bad-pdls.

Example:

  my $nc = PDL::NetCDF->new ("file1.nc", {REVERSE_DIMS => 1, PDL_BAD => 1});
  ...
  foreach my $ncfile (@a_bunch_of_similar_format_netcdf_files) {
    $nc = PDL::NetCDF->new("file2.nc", {TEMPLATE => $nc});  # These calls to 'new' are *much* faster
    ...
  }

  # opening using MODE
  use Fcntl; # define O_CREAT...
  # opening a completely new file (deleting if it exists!)
  my $newnc = PDL::NetCDF->new ("file2.nc", {MODE => O_CREAT|O_RDWR,
					     REVERSE_DIMS => 1, NC_FORMAT => PDL::NetCDF::NC_FORMAT_NETCDF4});
  # opening existing file for reading and writing
  $nc = PDL::NetCDF->new ("file2.nc", {MODE => O_RDWR}
			REVERSE_DIMS => 1});
  # opening existing file for reading only
  $nc = PDL::NetCDF->new ("file2.nc", {MODE => O_RDONLY,
				       REVERSE_DIMS => 1});

If this file exists and you want to write to it, 
prepend the name with the '>' character:  ">name.nc"

Returns:  The netCDF object.  Barfs if there is an error.

=for example
  $ncobj = PDL::NetCDF->new ("file.nc",{REVERSE_DIMS => 1});

=head2 getFormat

=for ref

Get the format of a netcdf file

=for usage

Arguments: none

Returns: 
@ integer equal to one of the PDL::NetCDF::NC_FORMAT_* constants.

=head2 put

=for ref

Put a PDL matrix to a netCDF variable.

=for usage

Arguments:  

1) The name of the variable to create

2) A reference to a list of dimension names for this variable

3) The PDL to put.  It must have the same number of dimensions
as specified in the dimension name list.

4) Optional options hashref: {SHUFFLE => 1, DEFLATE => 7, COMPRESS => 0, _FillValue => -32767}

Returns:
None.

=for example

  my $pdl = pdl [[1, 2, 3], [4, 5, 6]];

  # Specify variable name to put PDL in, plus names of the dimensions.  Dimension         
  # lengths are taken from the PDL, in this case, dim1 = 2 and dim2 = 3.      
  $ncobj->put ('var1', ['dim1', 'dim2'], $pdl);                                               
                                            
  # Now textual NetCDF arrays can be stored with PDL::Char style PDLs.  
  $str = PDL::Char->new (['Station1', 'Station2', 'Station3']);
  $obj->put ('stations', ['dim_station', 'dim_charlen'], $str);
  $outstr = $obj->get('stations');
  print $outstr;
  # Prints: ['Station1', 'Station2', 'Station3']
  # For more info on PDL::Char variables see PDL::Char(3), or perldoc PDL::Char

=head2 putslice

=for ref

Put a PDL matrix to a slice of a NetCDF variable

=for usage

Arguments:

1) The name of the variable to create

2) A reference to a list of dimension names for this variable

3) A reference to a list of dimensions for this variable

4) A reference to a list which specifies the N dimensional starting point of the slice.

5) A reference to a list which specifies the N dimensional count of the slice.

6) The PDL to put.  It must conform to the size specified by the 4th and 5th
   arguments.  The 2nd and 3rd argument are optional if the variable is already
   defined in the netcdf object. 

7) Optional options: {DEFLATE => 7, SHUFFLE => 0/1, _FillValue => -32767} will use
   gzip compression (level 7)
   on that variable and shuffle will not/will use the shuffle filter. These options are
   only valid for netcdf4 files. If you are unsure, test with 
   ($nc->getFormat >= PDL::NetCDF::NC_FORMAT::NC_FORMAT_NETCDF4)  

   In addition, netcdf4 does not allow changing the _FillValue attribute
   after the variable has been put/putslice'd. Therefore, the _FillValue
   can be set with an option to put/putslice.

Returns:
None.

=for example

  my $pdl = pdl [[1, 2, 3], [4, 5, 6]];

  # Specify variable name to put PDL in, plus names of the dimensions.  Dimension         
  # lengths are taken from the PDL, in this case, dim1 = 2 and dim2 = 3.      
  $ncobj->putslice ('var1', ['dim1', 'dim2', 'dim3'], [2,3,3], [0,0,0], [2,3,1], $pdl);                                               
  $ncobj->putslice ('var1', [], [], [0,0,2], [2,3,1], $pdl);                                               

  my $pdl2 = $ncobj->get('var1');

  print $pdl2;

  [
 [
  [          1 9.96921e+36           1]
  [          2 9.96921e+36           2]
  [          3 9.96921e+36           3]
 ]
 [
  [          4 9.96921e+36           4]
  [          5 9.96921e+36           5]
  [          6 9.96921e+36           6]
 ]
]

 note that the netcdf missing value (not 0) is filled in.    

=head2 sync

=for ref

Synchronize the data to the disk. Use this if you want to read
the file from another process without closing the file. This makes only
sense after put, puttext, putslice, putatt operations

=for usage

Returns:
nothing. Barfs on error.

=for example

  $ncobj->sync

=head2 get

=for ref

Get a PDL matrix from a netCDF variable.

=for usage

Arguments:  

1) The name of the netCDF variable to fetch.  If this is the only
argument, then the entire variable will be returned.

To fetch a slice of the netCDF variable, optional 2nd and 3rd arguments
must be specified:

2) A pdl which specifies the N dimensional starting point of the slice.

3) A pdl which specifies the N dimensional count of the slice.

Also, an options hashref may be passed.  The option 'NOCOMPRESS'
tells PDL::NetCDF to *not* try to uncompress
an compressed variable.  See the COMPRESS option on 'put' and 'putslice'
for more info.
The option 'PDL_BAD' tells PDL::NetCDF to translate _FillValue
or missing_value attributes to bad-values, e.g. NaN's.

Returns:
The PDL representing the netCDF variable.  Barfs on error.

=for example

  # A slice of the netCDF variable.
  # [0,0] is the starting point, [1,2] is the count.
  my $slice  = $ncobj->get ('var1', [0,0], [1,2], {NOCOMPRESS => 1, PDL_BAD => 1});

  # If var1 contains this:  [[1, 2, 3], [4, 5, 6]]
  # Then $slice contains: [1,2] (Size '1' dimensions are eliminated).

=head2 putatt

=for ref

putatt -- Attach a numerical or textual attribute to a NetCDF variable or the entire file.

=for usage

Arguments:

1) The attribute.  Either:  A one dimensional PDL (perhaps containing only one number) or
a string.

2) The name to give the attribute in the netCDF file.  Many attribute names
have pre-defined meanings.  See the netCDF documentation for more details.

3) Optionally, you may specify the name of the pre-defined netCDF variable to associate
this attribute with.  If this is left off, the attribute is a global one, pertaining to
the entire netCDF file.

Returns:
Nothing.  Barfs on error.

=for example

  # Attach a double attribute of size 3 to var1
  $ncobj->putatt (double([1,2,3]), 'double_attribute', 'var1');

  # Write a textual, global attribute.  'attr_name' is the attribute name.
  $ncobj->putatt ('The text of the global attribute', 'attr_name');          

=head2 getatt

=for ref

Get an attribute from a netCDF object.

=for usage

Arguments:

1) The name of the attribute (a text string).

2) The name of the variable this attribute is attached to.  If this
argument is not specified, this function returns a global attribute of
the input name.

=for example

  # Get a global attribute
  my $attr2 = $ncobj->getatt ('attr_name');

  # Get an attribute associated with the variable 'var1'
  my $attr1 = $ncobj->getatt ('double_attribute', 'var1');

=head2 getDeflateShuffle

=for ref

Get the deflate level and the shuffle flag for a variable.

=for usage

Can be called on all files, although only netcdf4 files support shuffle and deflate.

Arguments:

1) The name of the variable.

Returns:

($deflate, $shuffle) 

=for example

  my ($deflate, $shuffle) = $nc->getDeflateShuffle('varName');

=head2 getvariabletype

=for ref

Get a type of a variable from a netCDF object.

=for usage

Arguments:

1) The name of the variable.

Returns:
PDL::type or undef, when variable not defined

=for example

  # Get a type
  my $type = $ncobj->getvariabletype ('var1');

=head2 puttext

=for ref

Put a perl text string into a multi-dimensional NetCDF array.

=for usage

Arguments:

1) The name of the variable to be created (a text string).

2) A reference to a perl list of dimension names to use in creating this NetCDF array.

3) A reference to a perl list of dimension lengths.

4) A perl string to put into the netCDF array.  If the NetCDF array is 3 x 10, then the string must
   have 30 charactars.  

5) Optional nc4 options: {DEFLATE => 7, SHUFFLE => 0}

=for example

  my $str = "Station1  Station2  Station3  ";
  $obj->puttext('textvar', ['n_station', 'n_string'], [3,10], $str);

=head2 gettext

=for ref

Get a multi-dimensional NetCDF array into a perl string.

=for usage

Arguments:

1) The name of the NetCDF variable.

=for example

  my $outstr = $obj->gettext('textvar');

=head2 dimsize

=for ref

Get the size of a dimension from a netCDF object.

=for usage

Arguments:

1) The name of the dimension.

Returns:
The size of the dimension.

=for example

  my $dim1size = $ncobj->dimsize('dim1');

=head2 close

=for ref

Close a NetCDF object, writing out the file.

=for usage

Arguments:
None

Returns:
Nothing

This closing of the netCDF file can be done explicitly though the
'close' method.  Alternatively, a DESTROY block does an automatic
close whenever the netCDF object passes out of scope.

=for example

  $ncobj->close();

=head2 getdimensionnames ([$varname])

=for ref

Get all the dimension names from an open NetCDF object.  
If a variable name is specified, just return dimension names for
*that* variable.

=for usage

Arguments:
none

Returns:
An array reference of dimension names

=for example
  
  my $varlist = $ncobj->getdimensionnames();
  foreach(@$varlist){
    print "Found dim $_\n";
  }

=head2 getattributenames

=for ref

Get the attribute names for a given variable from an open NetCDF object.

=for usage

Arguments: Optional variable name, with no arguments it will return
the objects global netcdf attributes.

Returns:
An array reference of attribute names

=for example
  
  my $attlist = $ncobj->getattributenames('var1');

=head2 getvariablenames

=for ref

Get all the variable names for an open NetCDF object.

=for usage

Arguments:
 none.

Returns:
An array reference of variable names

=for example
  
  my $varlist = $ncobj->getvariablenames();

=head2 setrec

=for ref

Set up a 'record' of several 1D netCDF variables with the
same dimension.  Once this is set up, quick reading/writing
of one element from all variables can be put/get from/to a
perl list.

=for usage

Arguments:

 1) The names of all the netCDF variables to group into a record

Returns:
 A record name to use in future putrec/getrec calls

=for example

  my $rec = $ncobj->setrec('var1', 'var2', 'var3');

=head2 getrec

=for ref

Gets a 'record' (one value from each of several 1D netCDF
variables) previously set up using 'setrec'.  These values
are returned in a perl list.

=for usage

Arguments:

 1) The name of the record set up in 'setrec'.
 2) The index to fetch.

Returns:
 A perl list of all values.  Note that these variables
 can be of different types: float, double, integer, string.

=for example

  my @rec = $ncobj->getrec($rec, 5);

=head2 putrec

=for ref

Puts a 'record' (one value from each of several 1D netCDF
variables) previously set up using 'setrec'.  These values
are supplied as a perl list reference.

=for usage

Arguments:

 1) The name of the record set up in 'setrec'.
 2) The index to set.
 3) A perl list ref containing the values.

Returns:
 None.

=for example

  $ncobj->putrec($rec, 5, \@values);

=head1 WRITING NetCDF-FILES EFFICIENTLY

Writing several variables to NetCDF-files can take a long time. When a
new variable is attached by C<put> to a file, the attribute header has
to be written. This might force the internal netcdf-library to
restructure the complete file, and thus might take very much
IO-resources. By pre-defining the dimensions, attributes, and
variables, much time can be saved. Essentially the rule of thumb is to
define and write the data in the order it will be laid out in the
file. Talking PDL::NetCDF, this means the following:

=over 4

=item Open the netcdf file

    my $nc = new PDL::NetCDF('test.nc', {MODE => O_CREAT|O_RDWR,
					 REVERSE_DIMS => 1});

=item Write the global attributes

    $nc->putatt (double([1,2,3]), 'double_attribute');

=item Define all variables, make use of the NC_UNLIMITED dimension

   # here it is possible to choose float/double/short/long
   $pdl_init = long ([]);  
   for (my $i=0; $i<$it; $i++) {
       my $out2 = $nc->putslice("VAR$i",
	   		     ['x','y','z','t'],
		 	     [150,100,20,PDL::NetCDF::NC_UNLIMITED()],
			     [0,0,0,0],[1,0,0,0],$pdl_init);
   }

=item Write the variable-attributes

   $nc->putatt ("var-attr", 'attribute', 'VAR0'); 

=item Write data with putslice

    $nc->putslice("VAR5",[],[],[0,0,0,0],[$datapdl->dims],$datapdl);

=back

=head1 AUTHOR

Doug Hunt, dhunt\@ucar.edu.

=head2 CONTRIBUTORS

Heiko Klein, heiko.klein\@met.no
Edward Baudrez, Royal Meteorological Institute of Belgium, edward.baudrez\@meteo.be
Ed J (mohawk2), etj@cpan.org

=head1 SEE ALSO

perl(1), PDL(1), netcdf(3).

=cut

#line 1020 "netcdf.pd"
use Carp;
use Fcntl; # importing constants O_CREAT,O_RDONLY,O_RDWR
use constant DEBUG => 0;

#line 1030 "netcdf.pd"
use constant PACKTYPE => "Q*";

#line 1043 "netcdf.pd"
# These defines are taken from netcdf.h  I deemed this cleaner than using
# h2xs and the autoload stuff, which mixes awkwardly with PP.
sub NC_FILL_BYTE () { return -127; }
sub NC_FILL_CHAR () { return 0; }
sub NC_FILL_SHORT () { return -32767; }
sub NC_FILL_INT () { return -2147483647; }
sub NC_FILL_FLOAT () { return 9.9692099683868690e+36; } # near 15 * 2^119 
sub NC_FILL_DOUBLE () { return 9.9692099683868690e+36; }
sub NC_FILL_UBYTE () { return 255; }
sub NC_FILL_USHORT () { return 65535; }
sub NC_FILL_UINT () { return 4294967295; }
sub NC_FILL_INT64 () { return -9223372036854775806; }
sub NC_FILL_UINT64 () { return 18446744073709551614; }
sub NC_FILL_STRING () { return ""; }

sub NC_FORMAT_CLASSIC () { return 1; }
sub NC_FORMAT_64BIT () { return 2; }
sub NC_FORMAT_NETCDF4 () { return 3; }
sub NC_FORMAT_NETCDF4_CLASSIC () { return 4; }

sub NC_CLOBBER () { return 0; }
sub NC_NOWRITE () { return 0; }
sub NC_WRITE () { return 0x1; } # read & write 
sub NC_NOCLOBBER () { return 0x4; } # Don't destroy existing file on create 
sub NC_FILL () { return 0; }	 # argument to ncsetfill to clear NC_NOFILL 
sub NC_NOFILL () { return 0x100; }  # Don't fill data section an records 
sub NC_LOCK () { return 0x0400; }   # Use locking if available 
sub NC_SHARE () { return 0x0800; }  # Share updates, limit cacheing 
sub NC_UNLIMITED () {  return 0; }
sub NC_GLOBAL () { return -1; }

sub NC_MAX_DIMS () { return 100; }  # max dimensions per file 
sub NC_MAX_ATTRS () { return 2000; }# max global or per variable attributes 
sub NC_MAX_VARS () { return 2000; } # max variables per file 
sub NC_MAX_NAME () { return 128; }	 # max length of a name 
sub NC_MAX_VAR_DIMS () { return NC_MAX_DIMS; } # max per variable dimensions

sub NC_NOERR () { return 0; }       # No Error 
sub NC_EBADID () { return -33; }    # Not a netcdf id 
sub NC_ENFILE () { return -34; }    # Too many netcdfs open 
sub NC_EEXIST () { return -35; }    # netcdf file exists && NC_NOCLOBBER 
sub NC_EINVAL () { return -36; }    # Invalid Argument 
sub NC_EPERM  () { return -37; }    # Write to read only 
sub NC_ENOTINDEFINE () { return -38; } # Operation not allowed in data mode 
sub NC_EINDEFINE () { return -39; } # Operation not allowed in define mode 
sub NC_EINVALCOORDS () { return -40; } # Index exceeds dimension bound 
sub NC_EMAXDIMS () { return -41; }  # NC_MAX_DIMS exceeded 
sub NC_ENAMEINUSE () { return -42; }# String match to name in use 
sub NC_ENOTATT () { return -43; }   # Attribute not found 
sub NC_EMAXATTS () { return -44; }  # NC_MAX_ATTRS exceeded 
sub NC_EBADTYPE () { return -45; }  # Not a netcdf data type 
sub NC_EBADDIM () { return -46; }   # Invalid dimension id or name 
sub NC_EUNLIMPOS () { return -47; } # NC_UNLIMITED in the wrong index 
sub NC_EMAXVARS () { return -48; }	 # NC_MAX_VARS exceeded 
sub NC_ENOTVAR () { return -49; }	 # Variable not found 
sub NC_EGLOBAL () { return -50; }	 # Action prohibited on NC_GLOBAL varid 
sub NC_ENOTNC () { return -51; }	 # Not a netcdf file 
sub NC_ESTS   () { return -52; }	 # In Fortran, string too short 
sub NC_EMAXNAME () { return -53; }	 # NC_MAX_NAME exceeded 
sub NC_EUNLIMIT () { return -54; }	 # NC_UNLIMITED size already in use 
sub NC_ENORECVARS () { return -55; }# nc_rec op when there are no record vars 
sub NC_ECHAR () { return -56; }	 # Attempt to convert between text & numbers 
sub NC_EEDGE () { return -57; }	 # Edge+start exceeds dimension bound 
sub NC_ESTRIDE () { return -58; }	 # Illegal stride 
sub NC_EBADNAME () { return -59; }	 # Attribute or variable name
sub NC_ERANGE () { return -60; }	 # Math result not representable 
sub NC_ENOMEM () { return -61; }	 # Memory allocation (malloc) failure 
sub NC_SYSERR () { return (-31)};

sub NC_FATAL () { return 1};        # quit on netcdf error
sub NC_VERBOSE () { return 2};      # give verbose error messages

sub NC_BYTE () { return 1; }        # signed 1 byte integer 
sub NC_CHAR () { return 2; }        # ISO/ASCII character 
sub NC_SHORT () { return 3; }	 # signed 2 byte integer 
sub NC_INT () { return 4; }	 # signed 4 byte integer 
sub NC_FLOAT () { return 5; }       # single precision floating point number 
sub NC_DOUBLE () { return 6; }	 # double precision floating point number 
sub NC_UBYTE () { return 7; }    # unsigned 1 byte int
sub NC_USHORT () { return 8; }   # unsigned 2-byte int
sub NC_UINT () { return 9; }     # unsigned 4-byte int
sub NC_INT64 () { return 10; }   # signed 8-byte int
sub NC_UINT64 () { return 11; }  # unsigned 8-byte int
sub NC_STRING () { return 12; }  # string

# Used for creating new blank pdls with the input number of dimensions, and
# the correct type.
my %typemap = (
	       NC_BYTE()   => sub { PDL->zeroes (PDL::byte,   @_); },
	       NC_CHAR()   => sub { PDL::Char->new(PDL->zeroes (PDL::byte,   @_)); },
	       NC_SHORT()  => sub { PDL->zeroes (PDL::short,  @_); },
	       NC_INT()    => sub { PDL->zeroes (PDL::long,   @_); },
	       NC_FLOAT()  => sub { PDL->zeroes (PDL::float,  @_); },
	       NC_DOUBLE() => sub { PDL->zeroes (PDL::double, @_); },
	       NC_UBYTE()   => sub { PDL->zeroes (PDL::byte,   @_); },
	       NC_USHORT()  => sub { PDL->zeroes (PDL::ushort,  @_); },
	       NC_UINT()    => sub { PDL->zeroes (PDL::long,   @_); },
	       NC_INT64()    => sub { PDL->zeroes (PDL::longlong,   @_); },
	       NC_UINT64()    => sub { PDL->zeroes (PDL::longlong,   @_); },
	       );

# Used for creating new pdls with the input data, and
# the correct type.
my %typemap1 = (
		NC_BYTE()   => sub { PDL::byte  (@_); },
		NC_CHAR()   => sub { PDL::byte  (@_); },
		NC_SHORT()  => sub { PDL::short (@_); },
		NC_INT()    => sub { PDL::long  (@_); },
		NC_FLOAT()  => sub { PDL::float (@_); },
		NC_DOUBLE() => sub { PDL::double(@_); },
               NC_UBYTE()   => sub { PDL::byte (@_); },
               NC_USHORT()  => sub { PDL::ushort(@_); },
	       NC_UINT()    => sub { PDL::long(@_); },
	      NC_INT64()    => sub { PDL::longlong(@_); },
	     NC_UINT64()    => sub { PDL::longlong(@_); },
		);

# Used for creating new blank pdls with the input number of dimensions, and
# the correct type.
my %typemap2 = (
		PDL::byte->[0]   => sub { return PDL::NetCDF::nc_put_var_uchar  (@_); },
		PDL::short->[0]  => sub { return PDL::NetCDF::nc_put_var_short  (@_); },
		PDL::long->[0]   => sub { return PDL::NetCDF::nc_put_var_int    (@_); },
		PDL::float->[0]  => sub { return PDL::NetCDF::nc_put_var_float  (@_); },
		PDL::double->[0] => sub { return PDL::NetCDF::nc_put_var_double (@_); },
		PDL::ushort->[0]  => sub { return PDL::NetCDF::nc_put_var_ushort  (@_); },
		PDL::longlong->[0]   => sub { return PDL::NetCDF::nc_put_var_longlong (@_); },
		);

# Used for mapping a PDL type to a netCDF type
my %typemap3 = (
		PDL::byte->[0]   => NC_BYTE(), 
		PDL::short->[0]  => NC_SHORT(), 
		PDL::long->[0]   => NC_INT(), 
		PDL::float->[0]  => NC_FLOAT(), 
		PDL::double->[0] => NC_DOUBLE(), 
        PDL::ushort->[0] => NC_USHORT(),
        PDL::longlong->[0] => NC_INT64(),
		);

# Used for getting a netCDF variable for the correct type of a PDL
my %typemap4 = (
		PDL::byte->[0]   => sub { PDL::NetCDF::nc_get_var_uchar  (@_); },
		PDL::short->[0]  => sub { PDL::NetCDF::nc_get_var_short  (@_); },
		PDL::long->[0]   => sub { PDL::NetCDF::nc_get_var_int    (@_); },
		PDL::float->[0]  => sub { PDL::NetCDF::nc_get_var_float  (@_); },
		PDL::double->[0] => sub { PDL::NetCDF::nc_get_var_double (@_); },
		PDL::ushort->[0]   => sub { PDL::NetCDF::nc_get_var_ushort    (@_); },
		PDL::longlong->[0]   => sub { PDL::NetCDF::nc_get_var_longlong    (@_); },
		);

# Used for putting attributes of correct type for a PDL
my %typemap5 = (
		PDL::byte->[0]   => sub { return PDL::NetCDF::nc_put_att_uchar  (@_); },
		PDL::short->[0]  => sub { return PDL::NetCDF::nc_put_att_short  (@_); },
		PDL::long->[0]   => sub { return PDL::NetCDF::nc_put_att_int    (@_); },
		PDL::float->[0]  => sub { return PDL::NetCDF::nc_put_att_float  (@_); },
		PDL::double->[0] => sub { return PDL::NetCDF::nc_put_att_double (@_); },
		PDL::ushort->[0]   => sub { return PDL::NetCDF::nc_put_att_ushort    (@_); },
		PDL::longlong->[0]   => sub { return PDL::NetCDF::nc_put_att_longlong    (@_); },
		);

# Used for getting a netCDF attribute for the correct type of a PDL
my %typemap6 = (
		PDL::byte->[0]   => sub { PDL::NetCDF::nc_get_att_uchar  (@_); },
		PDL::short->[0]  => sub { PDL::NetCDF::nc_get_att_short  (@_); },
		PDL::long->[0]   => sub { PDL::NetCDF::nc_get_att_int    (@_); },
		PDL::float->[0]  => sub { PDL::NetCDF::nc_get_att_float  (@_); },
		PDL::double->[0] => sub { PDL::NetCDF::nc_get_att_double (@_); },
		PDL::ushort->[0]   => sub { PDL::NetCDF::nc_get_att_ushort    (@_); },
		PDL::longlong->[0]   => sub { PDL::NetCDF::nc_get_att_longlong    (@_); },
		);

# Used for getting a slice of a netCDF variable for the correct type of a PDL 
my %typemap7 = (
		PDL::byte->[0]   => sub { PDL::NetCDF::nc_get_vara_uchar  (@_); },
		PDL::short->[0]  => sub { PDL::NetCDF::nc_get_vara_short  (@_); },
		PDL::long->[0]   => sub { PDL::NetCDF::nc_get_vara_int    (@_); },
		PDL::float->[0]  => sub { PDL::NetCDF::nc_get_vara_float  (@_); },
		PDL::double->[0] => sub { PDL::NetCDF::nc_get_vara_double (@_); },
		PDL::ushort->[0]   => sub { PDL::NetCDF::nc_get_vara_ushort    (@_); },
		PDL::longlong->[0]   => sub { PDL::NetCDF::nc_get_vara_longlong    (@_); },
		);

# Used for putting a slice of a netCDF variable for the correct type of a PDL 
my %typemap8 = (
		PDL::byte->[0]   => sub { PDL::NetCDF::nc_put_vara_uchar  (@_); },
		PDL::short->[0]  => sub { PDL::NetCDF::nc_put_vara_short  (@_); },
		PDL::long->[0]   => sub { PDL::NetCDF::nc_put_vara_int    (@_); },
		PDL::float->[0]  => sub { PDL::NetCDF::nc_put_vara_float  (@_); },
		PDL::double->[0] => sub { PDL::NetCDF::nc_put_vara_double (@_); },
		PDL::ushort->[0]   => sub { PDL::NetCDF::nc_put_vara_ushort    (@_); },
		PDL::longlong->[0]   => sub { PDL::NetCDF::nc_put_vara_longlong    (@_); },
		);

my %fillmap = (
	       NC_BYTE()   => NC_FILL_BYTE(),
	       NC_CHAR()   => NC_FILL_CHAR(),
	       NC_SHORT()  => NC_FILL_SHORT(),
	       NC_INT()    => NC_FILL_INT(),
	       NC_FLOAT()  => NC_FILL_FLOAT(),
	       NC_DOUBLE() => NC_FILL_DOUBLE(),
	       NC_UBYTE()   => NC_FILL_UBYTE(),
	       NC_USHORT()  => NC_FILL_USHORT(),
	       NC_UINT()    => NC_FILL_UINT(),
	       NC_INT64()    => NC_FILL_INT64(),
	       NC_UINT64()    => NC_FILL_UINT64(),
	       );

# maps original type to compressed type
my %compressionMap = (
                      PDL::float->[0]  => PDL::short->[0],
                      PDL::double->[0] => PDL::long->[0],
                      );

# options one can specify in the call to new
my %legalopts = (
                 REVERSE_DIMS => 1,   # index in the C order, not the FORTRAN order
                 TEMPLATE     => 1,   # initialize this nc object with contents of a previous object
                 PERL_SCALAR  => 1,   # return single element PDLs as perl scalars
                 PDL_BAD      => 1,   # return missing values as PDL bad values
                 NC_FORMAT    => 1,   # choose the files format for new files, NC_FORMAT_*, see also defaultFormat
                 SLOW_CHAR_FETCH => 1, # read individual PDL::Char values in a loop instead of at once
                 DEBUG        => 1,
                );	

# get/set the format of PDL::NetCDF
sub defaultFormat {
	my ($format) = @_;
	my $oldFormat;
	if (defined $format) {
		my $rc = PDL::NetCDF::nc_set_default_format($format, $oldFormat=-999);
		barf ("Cannot change default format -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
	} else {
		my $rc = PDL::NetCDF::nc_set_default_format(NC_FORMAT_CLASSIC(), $oldFormat=-999);
		barf ("Cannot get default format -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
		if ($rc == NC_NOERR) {
			my $temp;
			$rc = PDL::NetCDF::nc_set_default_format($oldFormat, $temp=-999);
			barf ("Cannot get default format -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
		}
	}
	return $oldFormat;
}

# This routine hooks up an object to a NetCDF file.
sub new {
  my $type = shift;
  my $file = shift;

  my $opt  = shift || {};  # options hash

  my $fast = 0;  # fast new does not inquire about all variables and dimensions.
                 # This is assumed to have been done before.  All this info
                 # is taken from the previous nc object.  This is useful
	         # if one has to process many identical netCDF files.

  #
  ## Handle options
  #

  my $self = {};

  if (exists($$opt{TEMPLATE})) {
    $fast = 1;
    $self = $$opt{TEMPLATE};	
    delete $$opt{TEMPLATE};
  } 

  foreach my $optname (keys %$opt) {
    if ($legalopts{$optname}) {
      $self->{$optname} = $$opt{$optname};
    }
  }

  my $rc;
  my $write;

  if (exists($$opt{MODE})) { # write-mode
      if ($file =~ s/^\s*>//) {
	  carp "MODE set and $file starts with >: suppressing >";
      }
      my $create;
      if (($$opt{MODE} | O_CREAT | O_RDONLY | O_RDWR | O_EXCL) !=
	  (O_CREAT | O_RDONLY | O_RDWR | O_EXCL)) {
	  barf "unknown mode, only defined: O_CREAT,O_RDONLY,O_RDWR,O_EXCL";
      } elsif ($$opt{MODE} & O_EXCL) {
	  barf "opening O_EXCL, but file $file exists"
	      if (-f $file);
      } elsif ($$opt{MODE} & O_CREAT) {
	  my $create = 1;
	  if (-f $file) {
	      unlink $file 
		  or barf "Cannot remove $file: $!";
	  }
      } elsif (     O_RDONLY && ( $$opt{MODE} & O_RDONLY ) 
                || !O_RDONLY && ( ($$opt{MODE} & (O_CREAT | O_RDWR | O_EXCL)) == O_RDONLY ) ) {
          # O_RDONLY may be zero on some platforms
	  $write = 0;
	  unless (-f $file) {
	      barf "Cannot open readonly! No such file: $file";
	  }
      } elsif ($$opt{MODE} & O_RDWR) {
	  $write = 1;
	  unless (-f $file) {
	      unless ($create) {
		  barf "Cannot open rdwr! No such file: $file";
	      }
	  }
      } 
  } elsif (substr($file, 0, 1) eq '>') { # open for writing
    $file = substr ($file, 1);      # chop off >
    $write = 1;
  }
    
  if (-e $file or ($file =~ m{^https?://})) {

    if ($write) {

      $rc = PDL::NetCDF::nc_open ($file, NC_WRITE(), $self->{NCID}=-999);
      barf ("new:  Cannot open file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{WR} = 'w';

    } else { # Open read-only

      $rc = PDL::NetCDF::nc_open ($file, 0, $self->{NCID}=-999);
      barf ("new:  Cannot open file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{WR} = 'r';

      # Specify that this file is out of define mode
      $self->{DEFINE} = 0;

    }

    # Record file name
    $self->{FILENM} = $file;

    # don't bother to inquire about this file.  The info in the nc object 
    # passed in should suffice.
    return $self if ($fast);

    # Find out about variables, dimensions and global attributes in this file
    my ($ndims, $nvars, $ngatts, $unlimid);

#    $rc = PDL::NetCDF::nc_inq_ndims ($self->{NCID}, $ndims=-999);
#    barf ("new:  Cannot inquire ndims -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
#    $rc = PDL::NetCDF::nc_inq_nvars ($self->{NCID}, $nvars=-999);
#    barf ("new:  Cannot inquire nvars -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

    $rc = PDL::NetCDF::nc_inq ($self->{NCID}, $ndims=-999, $nvars=-999, $ngatts=-999, $unlimid=-999);
    barf ("new:  Cannot inquire -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    $self->{UNLIMID} = $unlimid;
    
    for (my $i=0;$i<$ndims;$i++) {
      $rc = PDL::NetCDF::nc_inq_dimname ($self->{NCID}, $i, 
					 my $name='x' x NC_MAX_NAME()); # Preallocate strings
      barf ("new:  Cannot inquire dim name -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
      $self->{DIMIDS}{$name} = $i;
      
      $rc = PDL::NetCDF::nc_inq_dimlen ($self->{NCID}, $i, my $len = -999);
      barf ("new:  Cannot inquire dim length -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
      $self->{DIMLENS}{$name} = $len;
    }
    
    for (my $i=0;$i<$nvars;$i++) {
      $rc = PDL::NetCDF::nc_inq_varname ($self->{NCID}, $i, 
					 my $name='x' x NC_MAX_NAME()); # Preallocate strings
      barf ("new:  Cannot inquire var name -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
      $self->{VARIDS}{$name} = $i;

      $rc  = PDL::NetCDF::nc_inq_vartype ($self->{NCID}, $self->{VARIDS}{$name}, 
					     $self->{DATATYPES}{$name}=-999);
      barf ("new:  Cannot inquire var type -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
      
      $rc = PDL::NetCDF::nc_inq_varnatts ($self->{NCID}, $i,
                                       my $natts=-999);
      barf ("new:  Cannot inquire natts -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
      for (my $j=0;$j<$natts; $j++) {
        $rc = PDL::NetCDF::nc_inq_attname ($self->{NCID}, $i, $j,
                                       my $attname='x' x NC_MAX_NAME()); # Preallocate strings
        barf ("new:  Cannot inquire att name -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	

        # Determine the type and length of this attribute
        $rc = PDL::NetCDF::nc_inq_atttype ($self->{NCID}, $i, $attname, my $datatype=-999);
        barf ("new:  Cannot get attribute type -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

        $rc = PDL::NetCDF::nc_inq_attlen ($self->{NCID}, $i, $attname, my $attlen=-999);
        barf ("new:  Cannot get attribute length -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

        $self->{ATTTYPE}{$name}{$attname}=$datatype;
        $self->{ATTLEN}{$name}{$attname}=$attlen;
      }

    }
    
    for (my $i=0;$i<$ngatts; $i++) {
      $self->{VARIDS}{GLOBAL}=NC_GLOBAL();
      $rc = PDL::NetCDF::nc_inq_attname ($self->{NCID},$self->{VARIDS}{GLOBAL} , $i,
                                       my $attname='x' x NC_MAX_NAME()); # Preallocate strings
      barf ("new:  Cannot inquire global att name -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	

        # Determine the type and length of this attribute
        $rc = PDL::NetCDF::nc_inq_atttype ($self->{NCID}, $self->{VARIDS}{GLOBAL}, $attname, my $datatype=-999);
        barf ("new:  Cannot get attribute type -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

        $rc = PDL::NetCDF::nc_inq_attlen ($self->{NCID}, $self->{VARIDS}{GLOBAL}, $attname, my $attlen=-999);
        barf ("new:  Cannot get attribute length -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

        $self->{ATTTYPE}{GLOBAL}{$attname}=$datatype;
        $self->{ATTLEN}{GLOBAL}{$attname}=$attlen;
    } 
  

    # Specify that this file is out of define mode
    $self->{DEFINE} = 0;
    
  } else { # new file
    my $oldFormat;
    defaultFormat($opt->{NC_FORMAT}, $oldFormat) if ($opt->{NC_FORMAT});
    $rc = PDL::NetCDF::nc_create ($file, NC_CLOBBER(), $self->{NCID}=-999);
    defaultFormat($oldFormat, my $tmp) if ($opt->{NC_FORMAT});
    barf ("new:  Cannot create netCDF file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;	
    
    # Specify that this file is now in define mode
    $self->{DEFINE} = 1;

    # Open for writing
    $self->{WR} = 'w';

  }
  
  # Record file name
  $self->{FILENM} = $file;

  bless $self, $type;
  return $self;
}

# Get the format of the file
sub getFormat {
	my ($self) = @_;
	my $format;
	my $rc = nc_inq_format($self->{NCID}, $format=-999);
	barf("Cannot get format -- " . PDL::NetCDF::nc_strerror($rc)) if $rc;
	return $format;
}

# Explicitly close a netCDF file and free the object
sub close {
  my $self = shift;
  my $retVal = 1;
  if ($self->{NCID} != -999) {
    $retVal = PDL::NetCDF::nc_close ($self->{NCID});
	$self->{NCID} = -999;
  }
  return $retVal;
}

# Close a netCDF object when it passes out of scope
sub DESTROY {
  my $self = shift;
  # print "Destroying $self\n";
  $self->close;
}

# Get deflate and shuffle level of a variable
sub getDeflateShuffle {
    my ($self, $varnm) = @_;
    return (0,0) if ($self->getFormat < PDL::NetCDF::NC_FORMAT_NETCDF4);
    barf ("getDeflateShuffle: undefined varname $varname") unless exists $self->{VARIDS}{$varnm};
    my ($deflate, $isDeflate, $shuffel);
    my $rc = nc_inq_var_deflate($self->{NCID}, $self->{VARIDS}{$varnm}, $shuffle=-999, $isDeflate=-999, $deflate=-999);
    barf ("getDeflateShuffle: ncerror on $varname -- ".nc_strerror($rc)) if $rc;
    return ($deflate, $shuffle);	
}

# Get the names and order of dimensions in a variable, otherwise
# get the names of all dimensions
sub getdimensionnames {
  my $self = shift;
  my $varnm = shift;
  my $dimnames = [];
  my $dimids = [values %{$self->{DIMIDS}}];
#line 1533 "netcdf.pd"
  if (defined $varnm) {
    my ($ndims, $rc);

    # Cannot call nc_inq_varndims unless $self->{VARIDS}{$varnm} is defined
    if (!defined($self->{VARIDS}{$varnm})) {
      $ndims = 0;
    } else {  # normal case
      $rc = PDL::NetCDF::nc_inq_varndims ($self->{NCID}, $self->{VARIDS}{$varnm}, $ndims=-999);
    }

    if ($ndims > 0) {
      $dimids = zeroes (PDL::long, $ndims);
      $rc |= PDL::NetCDF::nc_inq_vardimid ($self->{NCID}, $self->{VARIDS}{$varnm}, $dimids);
      barf ("getdimensionnames:  Cannot get info on this var id -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $dimids = [list $dimids];
    } else {
      $dimids = [];
    }
  }
  foreach my $id (@$dimids) {
    foreach(keys %{$self->{DIMIDS}}){
#line 1554 "netcdf.pd"
      push(@$dimnames,$_) if $self->{DIMIDS}{$_} == $id;
    }
  }

  if ($self->{REVERSE_DIMS}) {
      $dimnames = [ reverse @$dimnames ];
  }
  $dimnames;
}

# Return the names of all variables in the netCDF file.  Special care
# is taken to return them in the order defined in the file.
sub getvariablenames {
  my $self = shift;
  my @varnames = ();
  return [()] unless (exists $self->{VARIDS});
  for my $varn (keys %{$self->{VARIDS}}){
#line 1571 "netcdf.pd"
    next if($self->{VARIDS}{$varn} == NC_GLOBAL());
    push (@varnames, $varn);
  }

  @varnames = sort { $self->{VARIDS}{$a} <=> $self->{VARIDS}{$b} } (@varnames);
  return \@varnames;
} 

# Return the names of all attribute names in the netCDF file.
sub getattributenames {
  my $self = shift;
  my $varname = shift;
  $varname = 'GLOBAL' unless(defined $varname);
  my $attnames = [];
  foreach(keys %{$self->{ATTTYPE}{$varname}}){
#line 1586 "netcdf.pd"
        push(@$attnames,$_);
  }
  $attnames;
} 

sub sync {
  my $self  = shift;  # name of object
  $rc = PDL::NetCDF::nc_sync($self->{NCID});
  barf ("sync:  Cannot sync file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  return;
}

# Put a netCDF variable from a PDL
sub put {
  my $self  = shift;  # name of object
  my $varnm = shift;  # name of netCDF variable to create or update
  my $dims  = shift;  # set of dimensions, i.e. ['dim1', 'dim2']
  my $pdl   = shift;  # PDL to put
  my $opt   = shift || {};
  my $compress = delete $opt->{COMPRESS} || 0;
  my $deflate = delete $opt->{DEFLATE} || 0;
  my $shuffle = delete $opt->{SHUFFLE} || 0;
  my $fillValue = delete $opt->{_FillValue};
  barf ("Unknown options to put: ". join(",", keys %{$opt})) if (keys %{$opt});
#line 1610 "netcdf.pd"
  
  if ($self->{REVERSE_DIMS}) {
      $dims = [ reverse @$dims ];
  }

  barf "Cannot write read-only netCDF file $self->{FILENM}" if ($self->{WR} eq 'r');

  # Define dimensions if necessary

  my @dimlens = reverse $pdl->dims;

  my $dimids = (@dimlens > 0) ? zeroes (PDL::long, scalar(@dimlens)) : pdl [];
  my $dimlens = scalar (@$dims);

  for (my $i=0;$i<@$dims;$i++) {
    if (!defined($self->{DIMIDS}{$$dims[$i]})) {

      unless ($self->{DEFINE}) {
	my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
	barf ("Cannot put file into define mode") if $rc;
	$self->{DEFINE} = 1;
      }

      my $rc = PDL::NetCDF::nc_def_dim ($self->{NCID}, $$dims[$i], $dimlens[$i], 
				$self->{DIMIDS}{$$dims[$i]}=-999);
      barf ("put:  Cannot define dimension -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

      $self->{DIMLENS}{$$dims[$i]} = $dimlens[$i];

    }
    set ($dimids, $i, $self->{DIMIDS}{$$dims[$i]});

    barf ("put:  Attempt to redefine length of dimension $$dims[$i]")
      if ($self->{DIMLENS}{$$dims[$i]} != $dimlens[$i]);
    
  }

  my ($datatype, $pdltype);

  # Define variable if necessary
  if (!defined($self->{VARIDS}{$varnm})) {
  
    unless ($self->{DEFINE}) {
      my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
      barf ("put:  Cannot put file into define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{DEFINE} = 1;
    }

    if (ref($pdl) =~ /Char/) {  # a PDL::Char type PDL--write a netcdf char variable
      $datatype = NC_CHAR();
    } else {
      $pdltype  = $pdl->get_datatype;
      $pdltype  = $compressionMap{$pdltype} if ($compress);
      $datatype = $typemap3{$pdltype};
    }
    my $rc = PDL::NetCDF::nc_def_var ($self->{NCID}, $varnm, $datatype, 
			   $dimlens, $dimids, $self->{VARIDS}{$varnm}=-999);
    barf ("put:  Cannot define variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    if ($deflate || $shuffle) {
        my $doDeflate = $deflate > 0 ? 1 : 0;
        my $rc = PDL::NetCDF::nc_def_var_deflate($self->{NCID}, $self->{VARIDS}{$varnm}, $shuffle, $doDeflate, $deflate);
        barf ("put: Cannot shuffle/deflate variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    }
    $self->{DATATYPES}{$varnm} = $datatype;

  }

  # set _FillValue before data
  if (defined $fillValue) {
    $fillValue = PDL->zeroes($pdl->type, 1) + $fillValue
      if !ref $fillValue; # make it a pdl
    $self->putatt($fillValue, '_FillValue', $varnm);
  }

  # Make PDL physical
  $pdl->make_physical;

  # Get out of define mode
  if ($self->{DEFINE}) {
    my $rc = PDL::NetCDF::nc_enddef ($self->{NCID});
    barf ("put:  Cannot end define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    $self->{DEFINE} = 0;
  }

  # Call the correct 'put' routine depending on PDL type
  if (ref($pdl) =~ /Char/) {  # a PDL::Char type PDL--write a netcdf char variable
    $rc = PDL::NetCDF::nc_put_var_text ($self->{NCID}, $self->{VARIDS}{$varnm}, ${$pdl->get_dataref}); 
  } else {

    #
    ## compute a compressed PDL to put if compression is requested
    #
    if ($compress) {

      my $var = $pdl->copy;
      my ($min, $max) = $var->minmax;
      my $r1 = ($max - $min);
      my ($add_offset, $scale_factor, $newfill);

      if      ($pdltype == PDL::short->[0]) {  # original type = float,  new type = short
	my $r2 = 2**16 - 2;   # positive range of unsigned short with one left over for an error value (max short)
	$var -= $min;
	$var *= ($r2/$r1);
	$var -= 2**15;        # map values from min(short) to max(short)
	$newfill = (2**15)-1; # max(short) = fill value
	$var->inplace->setbadtoval($newfill);
	$rc = &{$typemap2{$pdltype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $var->short);
	$add_offset   = float([$min]);
	$scale_factor = float([$r1/$r2])
      } elsif ($pdltype == PDL::long->[0]) {  # original type = double, new type = long
	my $r2 = 2**32 - 2;   # positive range of unsigned long with one left over for an error value (max short)
	$var -= $min;
	$var *= ($r2/$r1);
	$var -= 2**31;        # map values from min(long) to max(long)
	$newfill = (2**31)-1; # max(long) = fill value
	$var->inplace->setbadtoval($newfill);
	$rc = &{$typemap2{$pdltype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $var->long);
	$add_offset   = double([$min]);
	$scale_factor = double([$r1/$r2]);
      } else {
        barf ("put (compressed):  compression of other than float or double variables not supported");
      }
      barf ("put (compressed):  Cannot write file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

      # write compression attributes
      $self->putatt($newfill,      '_FillValue',   $varnm);
      $self->putatt($add_offset,   'add_offset',   $varnm);
      $self->putatt($scale_factor, 'scale_factor', $varnm);

    } else { # no compression
      $rc = &{$typemap2{$pdl->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $pdl);
      barf ("put:  Cannot write file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    }

  }
  return 0;
}

#
# Put a netCDF variable slice (array section) from a PDL
# 
sub putslice {
  my $self  = shift;  # name of object
  my $varnm = shift;  # name of netCDF variable to create or update

  my $dims  = shift;  # set of dimensions, i.e. ['dim1', 'dim2']
  my $dimdefs = shift;# Need to state dims explicitly since the PDL is a subset

  my $start = shift;  # ref to perl array containing start of hyperslab to get
  my $count = shift;  # ref to perl array containing count along each dimension
  
  my $pdl   = shift;  # PDL to put
  my $opt = shift || {}; # options for deflate/shuffle
  my $deflate = delete $opt->{DEFLATE} || 0;
  my $shuffle = delete $opt->{SHUFFLE} || 0;
  my $fillValue = delete $opt->{_FillValue};
  barf ("Unknown options to putslice: ". join(",", keys %{$opt})) if (keys %{$opt});
#line 1768 "netcdf.pd"

  if ($self->{REVERSE_DIMS}) {
      $dims = [ reverse @$dims ];
      $dimdefs = [ reverse @$dimdefs ];
      $start = [ reverse @$start ];
      $count = [ reverse @$count ];
  }

  barf "Cannot write read-only netCDF file $self->{FILENM}" if ($self->{WR} eq 'r');

  if (!defined($self->{VARIDS}{$varnm})) {

  # Define dimensions if necessary
  my @dimlens =  @$dimdefs;

  my $dimids = zeroes (PDL::long, scalar(@dimlens));
  for (my $i=0;$i<@$dims;$i++) {
    if (!defined($self->{DIMIDS}{$$dims[$i]})) {

      unless ($self->{DEFINE}) {
	my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
	barf ("Cannot put file into define mode") if $rc;
	$self->{DEFINE} = 1;
      }

      my $rc = PDL::NetCDF::nc_def_dim ($self->{NCID}, $$dims[$i], $dimlens[$i], 
				$self->{DIMIDS}{$$dims[$i]}=-999);
      barf ("put:  Cannot define dimension -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

      $self->{UNLIMID} = $self->{DIMIDS}{$$dims[$i]} if ($dimlens[$i] == PDL::NetCDF::NC_UNLIMITED());
      $self->{DIMLENS}{$$dims[$i]} = $dimlens[$i];

    }
    set ($dimids, $i, $self->{DIMIDS}{$$dims[$i]});

    barf ("putslice:  Attempt to redefine length of dimension $$dims[$i]")
      if ($self->{DIMLENS}{$$dims[$i]} != $dimlens[$i]);
    
  }

  # Define variable if necessary

    unless ($self->{DEFINE}) {
      my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
      barf ("put:  Cannot put file into define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{DEFINE} = 1;
    }
    my $datatype;
    if (ref($pdl) =~ /Char/) {  # a PDL::Char type PDL--write a netcdf char variable
      $datatype = NC_CHAR();
    } else {
      $datatype = $typemap3{$pdl->get_datatype};
    }

    my $rc = PDL::NetCDF::nc_def_var ($self->{NCID}, $varnm, $datatype, 
			   scalar(@dimlens), $dimids, $self->{VARIDS}{$varnm}=-999);
    barf ("put:  Cannot define variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    if ($deflate || $shuffle) {
    	my $doDeflate = $deflate > 0 ? 1 : 0;
    	my $rc = PDL::NetCDF::nc_def_var_deflate($self->{NCID}, $self->{VARIDS}{$varnm}, $shuffle, $doDeflate, $deflate);
    	barf ("put: Cannot shuffle/deflate variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    }
    $self->{DATATYPES}{$varnm} = $datatype;

  }

  if (defined $fillValue) {
    $fillValue = PDL->zeroes($pdl->type, 1) + $fillValue
      if !ref $fillValue; # make it a pdl
    $self->putatt($fillValue, '_FillValue', $varnm);
  }

  # Make PDL physical
  $pdl->make_physical;

  # Get out of define mode
  if ($self->{DEFINE}) {
      my $rc = PDL::NetCDF::nc_enddef ($self->{NCID});
      barf ("put:  Cannot end define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{DEFINE} = 0;
  }

  # Convert start and count from perl lists to scalars
  my $st = pack (PACKTYPE, @$start);
  my $ct = pack (PACKTYPE, @$count);

  # Call the correct 'put' routine depending on PDL type
  if(ref($pdl) =~ /Char/)  {  # a PDL::Char type PDL--write a netcdf char variable
    $rc = PDL::NetCDF::nc_put_vara_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, ${$pdl->get_dataref});
  } else {
    $rc = &{$typemap8{$pdl->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, $pdl);
  }
  barf ("put:  Cannot write file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  
  return 0;
}

sub _recursiveGetStringSlice {
    my ($self, $varnm, $pdl, $start, $count, $curStart, $loopPos) = @_;
    if ($loopPos == (@$start - 1)) {
        # allocate a string max line-size, determined by last dimension
        my $t = ' ' x $count->[$loopPos];
        # only last count > 1;
        my @slice_count = map { 1 } @$count;
        $slice_count[-1] = $count->[$loopPos];
        my $st = pack (PACKTYPE, @$curStart);
        my $ct = pack (PACKTYPE, @slice_count);
        $rc = PDL::NetCDF::nc_get_vara_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, $t);
        my @pdlStart;
        for (my $i = 0; $i < $loopPos; $i++) {
            if ($count->[$i] > 1) { # slices with size 1 are reduced
                unshift @pdlStart, $curStart->[$i] - $start->[$i]; # reverse dims here!
            }
        }
        unless (@pdlStart) {
            $pdlStart[0] = 0;
        }
        $pdl->setstr(@pdlStart, $t);
    } else {
        for (my $i = 0; $i < $count->[$loopPos]; $i++) {
            my @thisStart = @$curStart;
            $thisStart[$loopPos] = $start->[$loopPos] + $i;
            # and now read the slice starting at thisPos
            _recursiveGetStringSlice($self, $varnm, $pdl, $start, $count, \@thisStart, $loopPos+1);
        }
    }
}

# Get the explicit or default _FillValue for a variable
sub _getFillValue {
  my ($self, $varnm) = @_;
  eval { $self->getatt('_FillValue', $varnm) } // $fillmap{$self->{DATATYPES}{$varnm}};
}

# Get a variable into a pdl
sub get {
  my $self  = shift;
  my $varnm = shift;

  # separate options hash (if present) from the rest of the args
  my ($opt) = grep { ref($_) =~ /HASH/ } @_;
  my @args  = grep { ref($_) !~ /HASH/ } @_;

  print "In get(): self = $self, varnm = $varnm\n" if ($self->{DEBUG});

  my $rc = 0;

  # Optional variables
  my $start = shift @args;  # ref to perl array containing start of hyperslab to get
  my $count = shift @args;  # ref to perl array containing count along each dimension
  if ($self->{REVERSE_DIMS}) {
      if (defined $start) {
	  $start = [ reverse @$start ];
      }
      if (defined $count) {
	  $count = [ reverse @$count ];
      }
  }
  barf ("Cannot find variable $varnm") if (!defined($self->{VARIDS}{$varnm}));

  my $pdl; # The PDL to return
  if (defined ($count)) {  # Get a hyperslab of the netCDF matrix

    # Get rid of length one dimensions.  @cnt used for allocating new blank PDL
    # to put data in.
    my @cnt = ();
    foreach my $elem (@$count) {
      push (@cnt, $elem) if ($elem != 1);
    }
    if (@cnt == 0) { @cnt = (1); }  # If count all ones, replace with single one

    # Note the 'reverse'! Necessary fiddling to get dimension order to work.
    $pdl = &{$typemap{$self->{DATATYPES}{$varnm}}}(reverse @cnt);	
    my $st = pack (PACKTYPE, @$start);
    my $ct = pack (PACKTYPE, @$count);
    # Get the data
    if (ref($pdl) =~ /Char/) {  # a PDL::Char type PDL--write a netcdf char variable

      # Determine the type of this variable.  We need this info to test if the first
      # dimension is unlimited.  D. Hunt 8/3/2009
      $rc = PDL::NetCDF::nc_inq_varndims ($self->{NCID}, $self->{VARIDS}{$varnm}, my $ndims=-999);
      barf ("get:  Cannot get number of variables -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;    	
      my $dimids = ($ndims > 0) ? zeroes (PDL::long, $ndims) : pdl [];
      $rc = PDL::NetCDF::nc_inq_vardimid ($self->{NCID}, $self->{VARIDS}{$varnm}, $dimids);
      barf ("get:  Cannot get info on this var id -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

      # If the first dim is the unlimited dim, this PDL needs to be read in slices.  D. Hunt 8/3/2009
      if ($self->{SLOW_CHAR_FETCH} || (defined $self->{UNLIMID} && $self->{UNLIMID} == $dimids->at(0))) {
        _recursiveGetStringSlice($self, $varnm, $pdl, $start, $count, $start, 0);
      } else { # first dim not the unlimited dimension
        my $f = ${$pdl->get_dataref};
        $rc = PDL::NetCDF::nc_get_vara_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, $f);
        ${$pdl->get_dataref} = $f;
        $pdl->upd_data();
      }

    } else {
      $rc = &{$typemap7{$pdl->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, $pdl);
    }
    barf ("get:  Cannot get data -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

  } else { # get whole netCDF matrix

    # Determine the type of this variable
    my ($ndims, $natts, $i);
    $rc = PDL::NetCDF::nc_inq_varndims ($self->{NCID}, $self->{VARIDS}{$varnm}, $ndims=-999);
    barf ("get:  Cannot get number of variables -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;    	
    my $dimids = ($ndims > 0) ? zeroes (PDL::long, $ndims) : pdl [];
    $rc = PDL::NetCDF::nc_inq_vardimid ($self->{NCID}, $self->{VARIDS}{$varnm}, $dimids);
    barf ("get:  Cannot get info on this var id -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

    print "In get(): ndims = $ndims, natts = $natts, dimids = $dimids\n" if ($self->{DEBUG});
    
    # Find out size of each dimension of this NetCDF matrix
    my ($name, $size, @cnt);
    for ($i=0;$i<$ndims;$i++) {
      my $rc = PDL::NetCDF::nc_inq_dim ($self->{NCID}, $dimids->at($i), $name='x' x NC_MAX_NAME(), $size=-999);
      barf ("get:  Cannot get info on this dimension -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      barf ("get:  Dimension must be positive") if ($size <= 0);  # Added to address zero length vars. D. Hunnt 4/29/2005
      push (@cnt, $size);
    }

    # Create empty PDL (of correct type and size) to hold output from NetCDF file
    if (defined($opt->{FETCH_AS})) {
       my $netcdf_type = $typemap3{$opt->{FETCH_AS}};  # FETCH_AS is the PDL type: PDL::byte->[0] ..PDL::longlong->[0]
       $pdl = &{$typemap{$netcdf_type}}(reverse @cnt);
    } else {
       $pdl = &{$typemap{$self->{DATATYPES}{$varnm}}}(reverse @cnt);
    }

    print "In get(): pdl = ", $pdl->info, " cnt = @cnt\n" if ($self->{DEBUG});

    # Get the data
    if (ref($pdl) =~ /Char/) {  # a PDL::Char type PDL--write a netcdf char variable

      # If the first dim is the unlimited dim, this PDL needs to be read in slices. D. Hunt 1/17/2003
      if ($self->{SLOW_CHAR_FETCH} || (defined $self->{UNLIMID} && $self->{UNLIMID} == $dimids->at(0))) {
        my @start = map {0} @cnt;
        _recursiveGetStringSlice($self, $varnm, $pdl, \@start, \@cnt, \@start, 0);
      } else {
        my $f = ${$pdl->get_dataref};
        $rc = PDL::NetCDF::nc_get_var_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $f);
        ${$pdl->get_dataref} = $f;	
        $pdl->upd_data();
      }
    } else {
      if (defined($opt->{FETCH_AS})) {
        $rc = &{$typemap4{$opt->{FETCH_AS}}}($self->{NCID}, $self->{VARIDS}{$varnm}, $pdl);
      } else {
        $rc = &{$typemap4{$pdl->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $pdl);
      }
      print "In get(): rc = $rc, pdl[info, first, last] = ", $pdl->info, " ", $pdl->at(0), " ", $pdl->at($pdl->nelem-1), "\n" if ($self->{DEBUG});
    }
    barf ("get:  Cannot get data -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  }

  #
  ## If this variable is compressed (simple netCDF offset/scale compression) then uncompress it.
  #
   unless ($opt->{NOCOMPRESS}) {
    if (defined (my $type = $self->{ATTTYPE}{$varnm}{'scale_factor'})) {
        print "In get(): why am I uncompressing?\n" if ($self->{DEBUG});
	my $scale_factor = $self->getatt('scale_factor', $varnm);
        my $add_offset   = $self->getatt('add_offset',   $varnm);
        my $fill         = $self->_getFillValue($varnm);
        $fill = $fill->at(0) if (ref($fill) =~ /PDL/);	# convert to perl scalar
        my $uncomp;
      if      ($type == NC_FLOAT()) {
        $uncomp = $pdl->float;  # create output PDL of float type
        $uncomp->inplace->setvaltobad($fill) if (defined($fill));
        $uncomp += 2**15;  # change signed short vals to unsigned short vals
      } elsif ($type == NC_DOUBLE()) {
        $uncomp = $pdl->double;  # create output PDL of float type
        $uncomp->inplace->setvaltobad($fill) if (defined($fill));
        $uncomp += 2**31;  # change signed long vals to unsigned long vals
      }
      $uncomp *= $scale_factor;
      $uncomp += $add_offset;
      $pdl = $uncomp;
    }
  }

  # convert netcdf fill/missing values to PDL badvals if requested and missing value is available
  if ($self->{PDL_BAD} || $opt->{PDL_BAD}) {
    my $fill = $self->_getFillValue($varnm);
    $fill = $fill->sclr if UNIVERSAL::isa($missing, 'PDL');
    $pdl->inplace->setvaltobad($fill) if (defined($fill));
    print "In get(): _FillValue = $fill, pdl[info] = ", $pdl->info, "\n" if ($self->{DEBUG});
    my $missing = eval { $self->getatt('missing_value', $varnm); };
    $missing = $missing->sclr if UNIVERSAL::isa($missing, 'PDL');
    $pdl->inplace->setvaltobad($missing) if (defined($missing));
    print "In get(): missing = $missing, pdl[info, first, last] = ", $pdl->info, " ", $pdl->at(0), " ", $pdl->at($pdl->nelem-1), "\n" if ($self->{DEBUG});
  }

  # convert single value PDLs to perl scalars if requested
  $pdl = (exists($self->{PERL_SCALAR}) and ($pdl->nelem == 1)) ? $pdl->at(0) : $pdl;

  return $pdl;
}

# Get the size of a dimension
sub dimsize {
  my $self  = shift;
  my $dimnm = shift;
  
  barf ("dimsize: No such dimension -- $dimnm") unless exists ($self->{DIMIDS}{$dimnm});

  my ($dimsz, $name);
  my $rc = nc_inq_dimlen ($self->{NCID}, $self->{DIMIDS}{$dimnm}, $dimsz=-999);
  barf ("dimsize:  Cannot get dimension length -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  return $dimsz;
}

# Put a netCDF attribute from a PDL or string
sub putatt {
  my $self  = shift;  # name of object
  my $att   = shift;  # Attribute to put.  Can be a string, a PDL, or a ref to a list of strings
  my $attnm = shift;  # Name of attribute to put
  my $varnm = shift;  # name of netCDF variable this attribute is to be associated with
                      # (defaults to global if not passed).

  barf "Cannot write read-only netCDF file $self->{FILENM}" if ($self->{WR} eq 'r');

  # If no varnm passed in, fetch a global attribute
  if (!defined($varnm)) { 
    $varnm = 'GLOBAL';
    $self->{VARIDS}{$varnm} = NC_GLOBAL();
  } 

  # Put netCDF file into define mode
  unless ($self->{DEFINE}) {
    my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
    barf ("putatt:  Cannot put file into define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    $self->{DEFINE} = 1;
  }

  # Attribute is a PDL one-D variable
  if (ref $att eq 'PDL') {

    barf ("Attributes can only be 1 dimensional") if ($att->dims != 1);

    # Make PDL physical
    $att->make_physical;

    # Put the attribute
    my $rc = &{$typemap5{$att->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, 
					      $attnm, $typemap3{$att->get_datatype},
					      nelem ($att), $att);
    barf ("putatt:  Cannot put PDL attribute -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
#
#  update self 
#

    $self->{ATTTYPE}{$varnm}{$attnm} = $typemap3{$att->get_datatype};
    $self->{ATTLEN}{$varnm}{$attnm} = $att->nelem;

  } elsif (ref $att eq '') {  # A scalar variable

    # Put the attribute
    my $rc = PDL::NetCDF::nc_put_att_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm,
			      length($att), $att."\0"); # null terminate!
    barf ("putatt:  Cannot put string attribute -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

#
#  update self 
#

    $self->{ATTTYPE}{$varnm}{$attnm} = NC_CHAR();
    $self->{ATTLEN}{$varnm}{$attnm} = length($att);

  } elsif (ref $att eq 'ARRAY') {  # A ref to a list:  Treat as a list of strings for string attributes

    # Put the attribute
    my $rc = PDL::NetCDF::nc_put_att_string ($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm,
			                     scalar(@$att), $att);
    barf ("putatt:  Cannot put string attribute -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

#
#  update self
#

    $self->{ATTTYPE}{$varnm}{$attnm} = NC_STRING();
    $self->{ATTLEN}{$varnm}{$attnm} = scalar(@$att);

  } else {

    barf ("Attributes of this type not supported");

  }

  # Get out of define mode
  if ($self->{DEFINE}) {
    my $rc = PDL::NetCDF::nc_enddef ($self->{NCID});
    barf ("put:  Cannot end define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    $self->{DEFINE} = 0;
  }

  return 0;
}

# Get an attribute value into a pdl
sub getatt {
  my $self  = shift;
  my $attnm = shift;
  my $varnm = shift;
  
  # If no varnm passed in, fetch a global attribute
  if (!defined($varnm)) { 
    $varnm = 'GLOBAL';
    $self->{VARIDS}{$varnm} = NC_GLOBAL();
  } 

  # Determine the type and length of this attribute
  my($datatype,$attlen);
  if(defined $self->{ATTTYPE}{$varnm}{$attnm}){
     $datatype = $self->{ATTTYPE}{$varnm}{$attnm};
     $attlen = $self->{ATTLEN}{$varnm}{$attnm};
  }else{
     barf ("getatt:  Attribute not found -- $varnm:$attnm");
  } 
#  $rc = PDL::NetCDF::nc_inq_atttype ($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm, my $datatype=-999);
#  barf ("getatt:  Cannot get attribute type -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
#
#  $rc = PDL::NetCDF::nc_inq_attlen ($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm, my $attlen=-999);
#  barf ("getatt:  Cannot get attribute length -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

  # Get text attribute into perl string
  if ($datatype == NC_CHAR()) {

    $rc = PDL::NetCDF::nc_get_att_text ($self->{NCID}, $self->{VARIDS}{$varnm}, 
			   $attnm, my $str=('x' x $attlen)."\0"); # null terminate!
    barf ("getatt:  Cannot get text attribute -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

    return $str;

  } elsif ($datatype == NC_STRING()) { # Handle the new string attributes

    my $str = PDL::NetCDF::nc_get_att_string ($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm, $attlen);
    return $str;

  }

  # Get PDL attribute

  # Create empty PDL (of correct type and size) to hold output from NetCDF file
  my $pdl = &{$typemap{$datatype}}($attlen);	

  # Get the attribute
  $rc = &{$typemap6{$pdl->get_datatype}}($self->{NCID}, $self->{VARIDS}{$varnm}, $attnm, $pdl);
  barf ("getatt:  Cannot get attribute -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  
  return (exists($self->{PERL_SCALAR}) and ($pdl->nelem == 1)) ? $pdl->at(0) : $pdl;

}

# Get the PDL-type of a variable
sub getvariabletype {
    my $self = shift;
    my $varnm = shift;
    unless (defined $self->{DATATYPES}{$varnm}) {
	# carp ("getvariabletype: variable $varnm not found, returning undef");
	return undef;
    }
    return $typemap1{$self->{DATATYPES}{$varnm}}();
}

# Put a perl string into a multi-dimensional netCDF object
#
## ex:  $o->puttext ('station_names', ['n_stations', 'n_string'], [3,10], 'Station1  Station2  Station3');
# 
sub puttext {
  my $self    = shift;
  my $varnm   = shift;
  my $dims    = shift;
  my $dimlens = shift;  # Length of dimensions
  my $str     = shift;  # Perl string with data
  my $opt = shift || {}; # options for deflate/shuffle
  my $deflate = delete $opt->{DEFLATE} || 0;
  my $shuffle = delete $opt->{SHUFFLE} || 0;
  barf ("Unknown options to puttext: ". join(",", keys %{$opt})) if (keys %{$opt});
#line 2251 "netcdf.pd"
  
  my $ndims = scalar(@$dimlens);

  barf "Cannot write read-only netCDF file $self->{FILENM}" if ($self->{WR} eq 'r');

  # Define dimensions if necessary

  my $dimids = zeroes (PDL::long, $ndims);
  for (my $i=0;$i<@$dims;$i++) {
    if (!defined($self->{DIMIDS}{$$dims[$i]})) {

      unless ($self->{DEFINE}) {
	my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
	barf ("Cannot put file into define mode") if $rc;
	$self->{DEFINE} = 1;
      }

      my $rc = PDL::NetCDF::nc_def_dim ($self->{NCID}, $$dims[$i], $$dimlens[$i], 
				$self->{DIMIDS}{$$dims[$i]}=-999);
      barf ("put:  Cannot define dimension -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

      $self->{DIMLENS}{$$dims[$i]} = $$dimlens[$i];

    }
    set ($dimids, $i, $self->{DIMIDS}{$$dims[$i]});

    barf ("put:  Attempt to redefine length of dimension $$dims[$i]")
      if ($self->{DIMLENS}{$$dims[$i]} != $$dimlens[$i]);
    
  }

  # Define variable if necessary
  if (!defined($self->{VARIDS}{$varnm})) {
  
    unless ($self->{DEFINE}) {
      my $rc = PDL::NetCDF::nc_redef ($self->{NCID});
      barf ("put:  Cannot put file into define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $self->{DEFINE} = 1;
    }

    my $datatype =  NC_CHAR();
    my $rc = PDL::NetCDF::nc_def_var ($self->{NCID}, $varnm, $datatype, 
			   $ndims, $dimids, $self->{VARIDS}{$varnm}=-999);
    barf ("put:  Cannot define variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    if ($deflate || $shuffle) {
        my $doDeflate = $deflate > 0 ? 1 : 0;
        my $rc = PDL::NetCDF::nc_def_var_deflate($self->{NCID}, $self->{VARIDS}{$varnm}, $shuffle, $doDeflate, $deflate);
        barf ("put: Cannot shuffle/deflate variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    }
    
    $self->{DATATYPES}{$varnm} = $datatype;

  }

  # Get out of define mode
  if ($self->{DEFINE}) {
    my $rc = PDL::NetCDF::nc_enddef ($self->{NCID});
    barf ("put:  Cannot end define mode -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
    $self->{DEFINE} = 0;
  }

  my $st = pack (PACKTYPE, ((0) x $ndims));
  my $ct = pack (PACKTYPE, @$dimlens);

  # Call the 'put' routine 
  $rc = PDL::NetCDF::nc_put_vara_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, $str."\0"); # null terminate!
  barf ("put:  Cannot write file -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  return 0;
}

# Get an entire text variable into one big string.  Multiple dimensions are concatenated.
sub gettext {
  my $self  = shift;
  my $varnm = shift;
  
  # Determine the type of this variable
  my ($ndims, $natts, $i, $rc);

  return '' unless (defined($self->{VARIDS}{$varnm}));

  $rc = PDL::NetCDF::nc_inq_varndims ($self->{NCID}, $self->{VARIDS}{$varnm}, $ndims=-999);
  barf ("get:  Cannot get number of variables -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;    		
  my $dimids = zeroes (PDL::long, $ndims);
  $rc = PDL::NetCDF::nc_inq_vardimid ($self->{NCID}, $self->{VARIDS}{$varnm}, $dimids);
  barf ("get:  Cannot get info on this var id -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
  # Find out size of each dimension of this NetCDF matrix
  my ($name, $size, $total_size, @dims);
  $total_size = 1;
  @dims = ();
  for ($i=0;$i<$ndims;$i++) {
      my $rc = PDL::NetCDF::nc_inq_dim ($self->{NCID}, $dimids->at($i), $name='x' x NC_MAX_NAME(), $size=-999);
      barf ("get:  Cannot get info on this dimension -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;
      $total_size *= $size;
      push (@dims, $size);
  }

  my $datatype = $self->{DATATYPES}{$varnm};

  # Get text attribute into perl string
  barf ("gettext:  Data not of string type") if ($datatype != NC_CHAR());

  my $st = pack (PACKTYPE, ((0) x $ndims));
  my $ct = pack (PACKTYPE, @dims);

  $rc = PDL::NetCDF::nc_get_vara_text ($self->{NCID}, $self->{VARIDS}{$varnm}, $st, $ct, my $str=('x' x $total_size)."\0"); # null terminate!
  barf ("gettext:  Cannot get text variable -- " . PDL::NetCDF::nc_strerror ($rc)) if $rc;

  return $str;

}

# Establish a 'record' (a group of 1D variables all having a shared dimension).
sub setrec {

  my $self = shift;
  my @vars = @_;

  my $varlist = $self->getvariablenames();

  my %dimhash = ();
  my @strdim  = ();
  foreach my $var (@vars) {
    die "Cannot find $var in netCDF file" if (!grep /^$var$/, @$varlist);
    my $dimname = $self->getdimensionnames($var);
    my $datatype = $self->{DATATYPES}{$var};
    if ($datatype == NC_CHAR) {
      die "Character variable $var has more than two dimensions" if (@$dimname > 2);
      push (@strdim, $self->{DIMLENS}{$$dimname[1]});
    } else {
      die "$var has more than one dimension" if (@$dimname > 1);
      push (@strdim, 0);
    }
    $dimhash{$$dimname[0]}++;
  }

  # Insist all variables must have the same dimension name
  die "All variables in a record must have the same dimension (which is not true here)"
    if (keys %dimhash > 1);

  my $recN = (defined($self->{MAXRECNUM}) ? $self->{MAXRECNUM} : 0) + 1;
  $self->{MAXRECNUM} = $recN;

  my $rec_name = "rec$recN";

  $self->{RECS}{$rec_name}{NAMES} = [@vars];

  # Store the data types of each variable in the record
  $self->{RECS}{$rec_name}{DATATYPES} = [map { $self->{DATATYPES}{$_} } @vars];

  # Store the variable IDs of each variable in the record $self->{VARIDS}{$name} = $i;
  $self->{RECS}{$rec_name}{VARIDS}    = [map { $self->{VARIDS}{$_} } @vars];

  # Store the lengths of string dimensions (if any) for all variables
  $self->{RECS}{$rec_name}{STRLEN}    = [@strdim];

  return $rec_name;

}

# Perl outer layer of the 'putrec' subroutine to update many 1D variables quickly
sub putrec {
  my $self   = shift;
  my $rec    = shift; # record name
  my $idx    = shift;
  my $values = shift;

  c_putrec ($self->{NCID}, $self->{RECS}{$rec}{VARIDS},
                           $self->{RECS}{$rec}{DATATYPES},
                           $self->{RECS}{$rec}{STRLEN},
                           $idx, $values);

}

# Perl outer layer of the 'getrec' subroutine to update many 1D variables quickly
#  my @rec = $ncobj->getrec($rec, 5);
sub getrec {
  my $self   = shift;
  my $rec    = shift; # record name
  my $idx    = shift;

  return c_getrec ($self->{NCID}, $self->{RECS}{$rec}{VARIDS},
                                  $self->{RECS}{$rec}{DATATYPES},
                                  $self->{RECS}{$rec}{STRLEN}, $idx);

}
#line 2165 "NetCDF.pm"

# Exit with OK status

1;
