package PDL::IO::ENVI;

use strict;
use warnings;
use PDL::LiteF;
use PDL::IO::FlexRaw;
use PDL::Exporter;
use Config;

our @ISA = qw( PDL::Exporter );
our @EXPORT_OK = qw( readenvi readenvi_hdr );
our @EXPORT = @EXPORT_OK;
our %EXPORT_TAGS = ( Func=>[@EXPORT_OK] );

our $VERSION = "2.098";
$VERSION = eval $VERSION;

our $verbose = 0;  # for diagnostics

=head1 NAME

PDL::IO::ENVI - read ENVI data files into PDL

=head1 SYNOPSIS

  use PDL::IO::ENVI;
  $pdl = readenvi("file.dat"); # implies there's a file.hdr next to it

  $hdr = readenvi_hdr("file.hdr"); # available separately, used for testing

=head1 DESCRIPTION

Allows you to read ENVI data into an ndarray.

=head1 FUNCTIONS

=head2 readenvi_hdr

=for ref

Given the name of an ENVI file header, parses the header and returns
a hash-ref.

  TODO
    (1) verify that all required fields are present
    (2) parse map_info for pixel geolocation
        - handle keyword=value inside list
    (3) check that all sensor keywords are parsed
    (4) add support for offset/stride/count/reshape
    (5) implement writeenvi/wenvi routine
    (6) LATER: add support for complex data input, e.g. [2,S,L,B]
    (7) LATER: support unsigned long long

=cut

# This is a hash ref of the known/allowed keywords
# in an ENVI header file.  While these are the current
# values, this implementation allows for new keywords
# by parsing according to the following rules:
#
#   (1) keywords are between the start of line and the =
#   (2) keywords are case insensitive
#   (3) white space is significant but amount and type is not
#   (4) string values will have leading and trailing whitespace removed
#   (5) canonical whitespace is a single ASCII space char
#   (6) single spaces in hash keywords will be replace by underscore
#   (7) canonical case for normalized keywords is lowercase
#   (8) required key-value pairs are always on a single line
#   (9) brace starting lists must be on same line as keyword =
#  (10) comment lines begin with ; in the first column
#
# Initially, we will parse all keyword = values but only fully
# process for the required and optional entries needed for the
# scissor data files.  A hash value of 1 indicates required..
#
my $envi_keywords = {
   'band_names' => 0,                     # optional, CSV str of band names
   'bands' => 1,                          # required, num of bands in image file
   'bbl' => 0,                            # optional, (tbd)
   'byte_order' => 1,                     # required, num 0 or 1 for LSF or MSF order
   'class_lookup' => 0,                   # optional, (tbd)
   'class_names' => 0,                    # optional, (tbd)
   'classes' => 0,                        # optional, num of classes, including unclassified
   'complex_function' => 0,               # optional, (tbd)
   'coordinate_system string' => 0,       # optional, (tbd, for georeferencing)
   'data_gain_values' => 0,               # optional, CSV of gain vals for each band
   'data_ignore_value' => 0,              # optional, value of bad/missing element in data
   'data_offset_values' => 0,             # optional, CSV of offset vals for each band
   'data_type' => 1,                      # required, id number in 1-6,9,12-15
   'default_bands' => 0,                  # optional, CSV of 1 or 3 band numbers to display
   'default_stretch' => 0,                # optional, str of stretch to use for image display
   'dem_band' => 0,                       # optional, (tbd)
   'dem_file' => 0,                       # optional, (tbd)
   'description' => 0,                    # optional, str describing the image or processing
   'file_type' => 1,                      # required, ENVI Standard or from filetype.txt
   'fwhm' => 0,                           # optional, CSV of band widths in wavelength units
   'geo_points' => 0,                     # optional, CSV of x,y,lat,long of 1-4 image pts
   'header_offset' => 1,                  # required, num bytes imbedded hdr in image file
   'interleave' => 1,                     # required, str/num of BSQ/0, BIL/1, or BIP/2
   'lines' => 1,                          # required, num lines in image
   'map_info' => 0,                       # optional, CSV of values, as in
                                          #  UTM, x0, y0, east0, north0, xpixsize, ypixsize,
                                          #  UTM zone #, N or S (UTM only), datum,
                                          #  units=str, rotation=val
   'pixel_size' => 0,                     # optional, CSV of x and y pixel size in meters
   'major_frame_offsets' => 0,            # optional, (tbd)
   'minor_frame_offsets' => 0,            # optional, (tbd)
   'projection_info' => 0,                # optional, (tbd)
   'reflectance_scale_factor' => 0,       # optional, (tbd)
   'rpc_info' => 0,                       # optional, (tbd)
   'samples' => 1,                        # required, num samples per image line each band
   'sensor_type' => 0,                    # optional, str Unknown or exact match in sensor.txt
   'spectra_names' => 0,                  # optional, (tbd)
   'wavelength' => 0,                     # optional, CSV of band center value in image
   'wavelength_units' => 0,               # optional, str with units for wavelength and fwhm
   'x_start' => 0,                        # optional, (tbd)
   'y_start' => 0,                        # optional, (tbd)
   'z_plot_average' => 0,                 # optional, (tbd)
   'z_plot_range' => 0,                   # optional, (tbd)
   'z_plot_titles' => 0,                  # optional, (tbd)
};

my $envi_required_keywords = [];
foreach (sort keys %$envi_keywords) {
   push @$envi_required_keywords, $_ if $envi_keywords->{$_};
}

my $interleave = {
   'bsq' => [ qw( samples lines   bands ) ],
   'bil' => [ qw( samples bands   lines ) ],
   'bip' => [ qw( bands   samples lines ) ],
};

my $envi_data_types = [];
$envi_data_types->[1]  =     'byte';
$envi_data_types->[2]  =    'short';
$envi_data_types->[3]  =     'long';
$envi_data_types->[4]  =    'float';
$envi_data_types->[5]  =   'double';
$envi_data_types->[6]  =      undef;  #        complex, not supported, [2,shape]
$envi_data_types->[9]  =      undef;  # double complex, not supported, [2,shape]
$envi_data_types->[12] =   'ushort';
$envi_data_types->[13] =    'ulong';
$envi_data_types->[14] = 'longlong';
$envi_data_types->[15] =      undef; # unsigned long64, not supported, longlong?

# Takes one arg, an ENVI hdr filename and
# returns a hash reference of the header data
#
sub readenvi_hdr {
   my $hdrname = $_[0];
   my $hdr = {};

   # an easy progress message
   if ($verbose>1) {
      print STDERR "readenvi_hdr: reading ENVI hdr data from '@_'\n";
      print STDERR "readenvi_hdr: required ENVI keywords are:\n";
      print STDERR "  @{ [sort @$envi_required_keywords] }\n";
   }

   # open hdr file
   open my $hdrfile, '<', $hdrname
      or barf "readenvi_hdr: couldn't open '$hdrname' for reading: $!";
   binmode $hdrfile;

   if ( eof($hdrfile) ) {
      barf "readenvi_hdr: WARNING '$hdrname' is empty, invalid ENVI format"
   }

   ITEM:
   while (!eof($hdrfile)) {
      # check for ENVI hdr start word on first line
      my $line = <$hdrfile>;
      if ($line !~ /^ENVI\r?$/) {
         barf "readenvi_hdr: '$hdrname' is not in ENVI hdr format"
      }
      $hdr->{ENVI} = 1;  # this marks this header as ENVI

      # collect key=values into a hash
      my ($keyword,$val);
      my $in_list = 0;     # used to track when we re reading a { } list
      LINE:
      while (defined($line = <$hdrfile>)) {

         next LINE if $line =~ /^;/;   # skip comment line (maybe print?)

         $line =~ s/\s+$//;
         $line =~ s/^\s+//;
         next LINE if $line =~ /^$/;

         chomp $line;

         if ($in_list>0) {
            # append to value string
            $val  .= " $line";  # need to keep whitespace for separation
            if ($line =~ /{/) {
               barf "readenvi_hdr: warning, found nested braces for line '$line'\n";
            }
            if ( $val =~ /}$/ ) { # got to end of list
               # parse $val list
               print STDERR "readenvi_hdr: got list value = $val\n" if $verbose>1;
               # clear list parse flag
               $in_list--;
            }
         } else {
            # look for next keyword = line
            ($keyword,$val) = (undef, undef);
            ($keyword,$val) = $line =~ /^\s*([^=]+)=\s*(.*)$/;
            if (defined $keyword) {
               # warning exit in case underscores are used in keywords
               if ($keyword =~ /_/) {
                  barf "readenvi_hdr: WARNING keyword '$keyword' contains underscore!"
               }
               # normalize to lc and single underscore for whitespace
               $keyword =~ s/\s+$//;
               $keyword =~ s/\s+/_/g;
               $keyword = lc $keyword;

               $val =~ s/^\s+//;
               $val =~ s/\s+$//;

               $in_list++ if $val =~ /^{/ and not $in_list;
               $in_list-- if $val =~ /}$/ and $in_list;

               next LINE if $in_list>0;

               # parse ENVI hdr lists and convert to perl array ref
               if ($val =~ /^{/) { # } vim gets confused
                  # strip off braces
                  $val =~ s/^{\s*//;
                  $val =~ s/\s*}$//;
                  my @listval = split ',\s*', $val;
                  print STDERR "readenvi_hdr: expanded $keyword list value to (@listval)\n" if $verbose;
                  $val = [@listval];
               }

               my $reqoropt = $envi_keywords->{$keyword} ? 'required' : 'optional';
               print STDERR "  got $reqoropt $keyword = $val\n" if $verbose;

               # replace ignore_value by data_ignore_value
               $keyword =~ s/^ignore_value$/data_ignore_value/;
               $hdr->{$keyword} = $val;

            } else {

               print STDERR "  NOT a 'keyword =' line: '$line'\n" if $verbose;

            }
         }
      }

   }
   # close hdr file
   close $hdrfile;
   return $hdr;
}

=head2 readenvi

=for ref

  reads ENVI standard format image files

=for usage

          $im = readenvi( filename );  # read image data
  ($im, $hdr) = readenvi( filename );  # read image data and hdr data hashref
  
  readenvi will look for an ENVI header file named filename.hdr
  
  If that file is not found, it will try with the windows
  convention of replacing the suffix of the filename by .hdr
  
  If valid header data is found, the image will be read and
  returned, with a ref to a hash of the hdr data in list
  context.
  
  NOTE: This routine only supports raw binary data at this time.

=cut

sub readenvi {
   barf 'Usage ($x [,$hdr]) = readenvi("filename")' if $#_ > 0;
   my $enviname = $_[0];

   my $envi;     # image data to return
   my $filehdr;  # image file header (before ENVI image data)
   my $envihdr;  # image hdr  to return
   my $flexhdr = [];

   # an easy progress message
   print STDERR "readenvi: reading ENVI data from '@_'\n" if $verbose;

   # read ENVI header
   my $envihdrname;

   $envihdrname = $enviname . '.hdr';
   if (! -f $envihdrname ) {
      $envihdrname = $enviname;
      $envihdrname =~ s/\.\w+$/.hdr/;
   }

   print STDERR "readenvi: ERROR could not find ENVI hdr file\n" unless -r $envihdrname;

   $envihdr = readenvi_hdr($envihdrname);

   # add read of imbedded_header data if have header_offset non-zero
   if ($envihdr->{header_offset}) {
      push @$flexhdr, { Type => 'byte', NDims => 1, Dims=>$envihdr->{header_offset} }
   }

   # see if we need to swap
   my $byteorder = ($Config{byteorder} =~ /4321$/) ? 1 : 0;
   print STDERR "readenvi: Config{byteorder} is $Config{byteorder}\n" if $verbose>1;
   if ($byteorder != $envihdr->{byte_order}) {
      print STDERR "readenvi: got byteorder of $byteorder, ENVI file has $envihdr->{byte_order}\n" if $verbose;
      print STDERR "readenvi: adding { Type => 'swap' } to \$flexhdr\n" if $verbose;
      push @$flexhdr, { Type => 'swap' } if $byteorder != $envihdr->{byte_order};
   }

   # determine data type for readflex from interleave header value
   my $imagespec = { };
   my $imagetype =  $envi_data_types->[$envihdr->{data_type}]; 
   print STDERR "readenvi: setting image { Type => $imagetype }\n" if $verbose;
   $imagespec->{Type} = $imagetype;
 
   # construct Dims for readflex
   my @imagedims = ();
   @imagedims = @{$interleave->{lc($envihdr->{interleave})}};
   print STDERR "readenvi: Need Dims => @imagedims\n" if $verbose;
   my $imagedims = [ map { $envihdr->{$_} } @imagedims ];
   print STDERR "readenvi: computed Dims => [", join( ', ', @{$imagedims} ), "]\n" if $verbose; 
   $imagespec->{Dims} = $imagedims;
   $imagespec->{Ndims} = scalar(@$imagedims);
   push @$flexhdr, $imagespec;

   # read file using readflex
   my (@envidata) = readflex( $enviname, $flexhdr );
   if (2==@envidata) {
      ($filehdr,$envi) = @envidata;
      $envihdr->{imbedded_header} = $filehdr;
   } else {
      ($envi) = @envidata;
   }

   # attach ENVI hdr to ndarray
   $envi->sethdr($envihdr);

   # handle ignore values by mapping to BAD
   if ( exists $envihdr->{data_ignore_value} ) {
      $envi->inplace->badflag;  # set badflag for image
      $envi->inplace->setvaltobad($envihdr->{data_ignore_value});
   }

   # return data and optionally header if requested
   return wantarray ? ($envi, $envihdr) : $envi;
}

=head1 SEE ALSO

Sample data: L<https://www.nv5geospatialsoftware.com/Support/Self-Help-Tools/Tutorials>

Header description: L<https://www.nv5geospatialsoftware.com/docs/enviheaderfiles.html>

Raster description: L<https://www.nv5geospatialsoftware.com/docs/enviimagefiles.html>

=cut

1;
