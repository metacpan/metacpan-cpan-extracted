
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::IO::GD;

@EXPORT_OK  = qw( PDL::PP write_png PDL::PP write_png_ex PDL::PP write_true_png PDL::PP write_true_png_ex  write_png_best write_true_png_best  recompress_png_best  load_lut read_png read_true_png PDL::PP _read_true_png PDL::PP _read_png PDL::PP _gd_image_to_pdl_true PDL::PP _gd_image_to_pdl PDL::PP _pdl_to_gd_image_true PDL::PP _pdl_to_gd_image_lut  read_png_lut PDL::PP _read_png_lut PDL::PP _gdImageColorAllocates PDL::PP _gdImageColorAllocateAlphas PDL::PP _gdImageSetPixels PDL::PP _gdImageLines PDL::PP _gdImageDashedLines PDL::PP _gdImageRectangles PDL::PP _gdImageFilledRectangles PDL::PP _gdImageFilledArcs PDL::PP _gdImageArcs PDL::PP _gdImageFilledEllipses  gdAlphaBlend   gdTrueColor   gdTrueColorAlpha   gdFree   gdFontGetLarge   gdFontGetSmall   gdFontGetMediumBold   gdFontGetGiant   gdFontGetTiny  );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::GD ;




=head1 NAME

PDL::IO::GD - Interface to the GD image library.

=head1 SYNOPSIS

 my $pdl = sequence(byte, 30, 30);
 write_png($pdl, load_lut($lutfile), "test.png");

 write_true_png(sequence(100, 100, 3), "test_true.png");

 my $image = read_png("test.png");

 my $image = read_true_png("test_true_read.png");
 write_true_png($image, "test_true_read.out.png");

 my $lut = read_png_lut("test.png");

 $pdl = sequence(byte, 30, 30);
 write_png_ex($pdl, load_lut($lutfile), "test_nocomp.png", 0);
 write_png_ex($pdl, load_lut($lutfile), "test_bestcomp1.png", 9);
 write_png_best($pdl, load_lut($lutfile), "test_bestcomp2.png");

 $pdl = sequence(100, 100, 3);
 write_true_png_ex($pdl, "test_true_nocomp.png", 0);
 write_true_png_ex($pdl, "test_true_bestcomp1.png", 9);
 write_true_png_best($pdl, "test_true_bestcomp2.png");

 recompress_png_best("test_recomp_best.png");

=head1 DESCRIPTION

This is the "General Interface" for the PDL::IO::GD library, and is actually several
years old at this point (read: stable). If you're feeling frisky, try the new OO 
interface described below.

The general version just provides several image IO utility functions you can use with
piddle variables. It's deceptively useful, however.

=cut








=head1 FUNCTIONS



=cut






=head2 write_png

=for sig

  Signature: (byte img(x,y); byte lut(i,j); char* filename)

Writes a 2-d PDL variable out to a PNG file, using the supplied color look-up-table piddle
(hereafter referred to as a LUT).

The LUT contains a line for each value 0-255 with a corresponding R, G, and B value.


=for bad

write_png does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*write_png = \&PDL::write_png;





=head2 write_png_ex

=for sig

  Signature: (img(x,y); lut(i,j); char* filename; int level)

=for ref

Same as write_png(), except you can specify the compression level (0-9) as the last argument.


=for bad

write_png_ex does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*write_png_ex = \&PDL::write_png_ex;





=head2 write_true_png

=for sig

  Signature: (img(x,y,z); char* filename)

Writes an (x, y, z(3)) PDL variable out to a PNG file, using a true color format.

This means a larger file on disk, but can contain more than 256 colors.


=for bad

write_true_png does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*write_true_png = \&PDL::write_true_png;





=head2 write_true_png_ex

=for sig

  Signature: (img(x,y,z); char* filename; int level)

=for ref

Same as write_true_png(), except you can specify the compression level (0-9) as the last argument.


=for bad

write_true_png_ex does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*write_true_png_ex = \&PDL::write_true_png_ex;




=head2 write_png_best( $img(piddle), $lut(piddle), $filename )

Like write_png(), but it assumes the best PNG compression (9).

=cut


sub write_png_best
{
    my $img = shift;
    my $lut = shift;
    my $filename = shift;
    return write_png_ex( $img, $lut, $filename, 9 );
} # End of write_png_best()...

=head2 write_true_png_best( $img(piddle), $filename )

Like write_true_png(), but it assumes the best PNG compression (9).

=cut


sub write_true_png_best
{
    my $img = shift;
    my $filename = shift;
    return write_true_png_ex( $img, $filename, 9 );
} # End of write_true_png_best()...






=head2 load_lut( $filename )

Loads a color look up table from an ASCII file. returns a piddle

=cut


sub load_lut
{
    return xchg(byte(cat(rcols(shift))), 0, 1);
} # end of load_lut()...

=head2 read_png( $filename )

Reads a (palette) PNG image into a (new) PDL variable.

=cut


sub read_png
{
    my $filename = shift;

    # Get the image dims...
    my $x = _get_png_xs($filename);
    my $y = _get_png_ys($filename);
    #print "\$x=$x\t\$y=$y\n";

    my $temp = zeroes(long, $x, $y);
    _read_png($temp, $filename);
    return byte($temp);
} # End of read_png()...

=head2 read_png_true( $filename )

Reads a true color PNG image into a (new) PDL variable.

=cut


sub read_true_png
{
    my $filename = shift;

    # Get the image dims...
    my $x = _get_png_xs($filename);
    my $y = _get_png_ys($filename);
    #print "\$x=$x\t\$y=$y\n";


    my $temp = zeroes(long, $x, $y, 3);
    _read_true_png($temp, $filename);
    return byte($temp);
} # End of read_png()...






*_read_true_png = \&PDL::_read_true_png;





*_read_png = \&PDL::_read_png;





*_gd_image_to_pdl_true = \&PDL::_gd_image_to_pdl_true;





*_gd_image_to_pdl = \&PDL::_gd_image_to_pdl;





*_pdl_to_gd_image_true = \&PDL::_pdl_to_gd_image_true;





*_pdl_to_gd_image_lut = \&PDL::_pdl_to_gd_image_lut;




=head2 my $lut = read_png_lut( $filename )

Reads a color LUT from an already-existing palette PNG file.

=cut


sub read_png_lut
{
    my $filename = shift;
    my $lut = zeroes(byte, 3, 256);
    _read_png_lut($lut, $filename);
    return $lut;
} # End of read_png_lut()...




*_read_png_lut = \&PDL::_read_png_lut;





*_gdImageColorAllocates = \&PDL::_gdImageColorAllocates;





*_gdImageColorAllocateAlphas = \&PDL::_gdImageColorAllocateAlphas;





*_gdImageSetPixels = \&PDL::_gdImageSetPixels;





*_gdImageLines = \&PDL::_gdImageLines;





*_gdImageDashedLines = \&PDL::_gdImageDashedLines;





*_gdImageRectangles = \&PDL::_gdImageRectangles;





*_gdImageFilledRectangles = \&PDL::_gdImageFilledRectangles;





*_gdImageFilledArcs = \&PDL::_gdImageFilledArcs;





*_gdImageArcs = \&PDL::_gdImageArcs;





*_gdImageFilledEllipses = \&PDL::_gdImageFilledEllipses;



;


=head1 OO INTERFACE
 
Object Oriented interface to the GD image library.

=head1 SYNOPSIS

 # Open an existing file:
 # 
 my $gd = PDL::IO::GD->new( { filename => "test.png" } );
 
 # Query the x and y sizes:
 my $x = $gd->SX();
 my $y = $gd->SY();

 # Grab the PDL of the data:
 my $pdl = $gd->to_pdl();

 # Kill this thing:
 $gd->DESTROY();

 # Create a new object:
 # 
 my $im = PDL::IO::GD->new( { x => 300, y => 300 } );

 # Allocate some colors:
 #
 my $black = $im->ColorAllocate( 0, 0, 0 );
 my $red = $im->ColorAllocate( 255, 0, 0 );
 my $green = $im->ColorAllocate( 0, 255, 0 );
 my $blue = $im->ColorAllocate( 0, 0, 255 );

 # Draw a rectangle:
 $im->Rectangle( 10, 10, 290, 290, $red );

 # Add some text:
 $im->String( gdFontGetLarge(), 20, 20, "Test Large Font!", $green );

 # Write the output file:
 $im->write_Png( "test2.png" );

=head1 DESCRIPTION

This is the Object-Oriented interface from PDL to the GD image library.

See L<http://www.boutell.com/gd/> for more information on the GD library and how it works.

=head2 IMPLEMENTATION NOTES

Surprisingly enough, this interface has nothing to do with the other Perl->GD interface module, 
aka 'GD' (as in 'use GD;'). This is done from scratch over the years.

Requires at least version 2.0.22 of the GD library, but it's only been thoroughly tested with
gd-2.0.33, so it would be best to use that. The 2.0.22 requirement has to do with a change in
GD's font handling functions, so if you don't use those, then don't worry about it.

I should also add, the statement about "thoroughly tested" above is mostly a joke. This OO 
interface is very young, and it has I<barely> been tested at all, so if something 
breaks, email me and I'll get it fixed ASAP (for me).

Functions that manipulate and query the image objects generally have a 'gdImage' prefix on the
function names (ex: gdImageString()). I've created aliases here for all of those member 
functions so you don't have to keep typing 'gdImage' in your code, but the long version are in 
there as well.

=head1 METHODS

=cut

use PDL;
use PDL::Slices;
use PDL::IO::Misc;

#
# Some helper functions:
#
sub _pkg_name
    { return "PDL::IO::GD::" . (shift) . "()"; }

# ID a file type from it's filename:
sub _id_image_file
{
    my $filename = shift;
    
    return 'png'
        if( $filename =~ /\.png$/ );
    
    return 'jpg'
        if( $filename =~ /\.jpe?g$/ );
    
    return 'wbmp'
        if( $filename =~ /\.w?bmp$/ );
    
    return 'gd'
        if( $filename =~ /\.gd$/ );
    
    return 'gd2'
        if( $filename =~ /\.gd2$/ );
    
    return 'gif'
        if( $filename =~ /\.gif$/ );
    
    return 'xbm'
        if( $filename =~ /\.xbm$/ );
        
    return undef;
} # End of _id_image_file()...

# Load a new file up (don't read it yet):
sub _img_ptr_from_file
{
    my $filename = shift;
    my $type = shift;
    
    return _gdImageCreateFromPng( $filename )
        if( $type eq 'png' );
    
    return _gdImageCreateFromJpeg( $filename )
        if( $type eq 'jpg' );
        
    return _gdImageCreateFromWBMP( $filename )
        if( $type eq 'wbmp' );
        
    return _gdImageCreateFromGd( $filename )
        if( $type eq 'gd' );
    
    return _gdImageCreateFromGd2( $filename )
        if( $type eq 'gd2' );
    
    return _gdImageCreateFromGif( $filename )
        if( $type eq 'gif' );
            
    return _gdImageCreateFromXbm( $filename )
        if( $type eq 'xbm' );
    
    return undef;
} # End of _img_ptr_from_file()...

# ID a file type from it's "magic" header in the image data:
sub _id_image_data 
{
    my $data = shift;
    my $magic = substr($data,0,4);
    
    return 'png'
        if( $magic eq "\x89PNG" );
    
    return 'jpg'
        if( $magic eq "\377\330\377\340" );
    return 'jpg'
        if( $magic eq "\377\330\377\341" );
    return 'jpg'
        if( $magic eq "\377\330\377\356" );
        
    return 'gif'
        if( $magic eq "GIF8" );
    
    return 'gd2'
        if( $magic eq "gd2\000" );
        
    # Still need filters for WBMP and .gd!
    
    return undef;
} # End of _id_image_data()...


# Load a new data scalar up:
sub _img_ptr_from_data
{
    my $data = shift;
    my $type = shift;
    
    return _gdImageCreateFromPngPtr( $data )
        if( $type eq 'png' );
    
    return _gdImageCreateFromJpegPtr( $data )
        if( $type eq 'jpg' );
        
    return _gdImageCreateFromWBMPPtr( $data )
        if( $type eq 'wbmp' );
        
    return _gdImageCreateFromGdPtr( $data )
        if( $type eq 'gd' );
    
    return _gdImageCreateFromGd2Ptr( $data )
        if( $type eq 'gd2' );
    
    return _gdImageCreateFromGifPtr( $data )
        if( $type eq 'gif' );
    
    return undef;
} # End of _img_ptr_from_data()...


=head2 new

Creates a new PDL::IO::GD object.

Accepts a hash describing how to create the object. Accepts a single hash ( with
curly braces ), an inline hash (the same, but without the braces) or a single
string interpreted as a filename. Thus the following are all equivalent:

 PDL::IO::GD->new( {filename => 'image.png'} );
 PDL::IO::GD->new( filename => 'image.png' );
 PDL::IO::GD->new( 'image.png' );

If the hash has:

 pdl => $pdl_var (lut => $lut_piddle)
    Then a new GD is created from that PDL variable.

 filename => $file
    Then a new GD is created from the image file.
    
 x => $num, y => $num
    Then a new GD is created as a palette image, with size x, y
    
 x => $num, y => $num, true_color => 1
    Then a new GD is created as a true color image, with size x, y

 data => $scalar (type => $typename)
    Then a new GD is created from the file data stored in $scalar. 
    If no type is given, then it will try to guess the type of the data, but 
        this will not work for WBMP and gd image types. For those types, you 
        _must_ specify the type of the data, or the operation will fail.
    Valid types are: 'jpg', 'png', 'gif', 'gd', 'gd2', 'wbmp'.
    
Example:
 
 my $gd = PDL::IO::GD->new({ pdl => $pdl_var });
    
 my $gd = PDL::IO::GD->new({ pdl => $pdl_var, lut => $lut_piddle });
 
 my $gd = PDL::IO::GD->new({ filename => "image.png" });
 
 my $gd = PDL::IO::GD->new({ x => 100, y => 100 });
 
 my $gd = PDL::IO::GD->new({ x => 100, y => 100, true_color => 1 });
 
 my $gd = PDL::IO::GD->new({ data => $imageData });
 
 my $gd = PDL::IO::GD->new({ data => $imageData, type => 'wbmp' });

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    #my $self  = $class->SUPER::new( @_ );
    my $self = {};
    
    my $sub = _pkg_name( "new" );
    
    # Figure out our options:

    # I want a single hash. I handle several cases here
    my $options;
    if( @_ == 1 && ref $_[0] eq 'HASH' ) {
      # single hash argument. Just take it
      $options = shift;
    }
    elsif( @_ == 1 && ! ref $_[0] ) {
      # single scalar argument. Treat it as a filename by default
      my $filename = shift;
      $options = { filename => $filename };
    }
    else {
      # the only other acceptable option is an inline hash. This is valid if I
      # have an even number of arguments, and the even-indexed ones (the keys)
      # are scalars
      if( @_ % 2 == 0 ) {
        my @pairs = @_;
        my $Npairs = scalar(@pairs)/2;

        use List::MoreUtils 'none';
        if( List::MoreUtils::none { ref $pairs[2*$_] } 0..$Npairs-1 ) {
          # treat the arguments as a hash
          $options = { @pairs }
        }
      }
    }

    if( !defined $options ) {
      die <<EOF;
PDL::IO::GD::new couldn't parse its arguments.
Expected a hash-ref or an inline hash or just a filename
EOF
    }


    
    if( defined( $options->{pdl} ) )
    {   # Create it from a PDL variable:
        my $pdl = $options->{pdl};
        $pdl->make_physical();
        my $num_dims = scalar( $pdl->dims() );
        if( $num_dims == 2 )
        {
            if( defined( $options->{lut} ) )
            {
                my $ptr = zeroes( longlong, 1 );
                my $lut = $options->{lut};
                _pdl_to_gd_image_lut( $pdl, $lut, $ptr );
#		print STDERR "in new (with lut), setting IMG_PTR to " . $ptr->at(0) . "\n";
                $self->{IMG_PTR} = $ptr->at(0);
                $ptr = null;
                die "$sub: _pdl_to_gd_image_lut() failed!\n"
                    if( $self->{IMG_PTR} == 0 );
            }
            else
            {
                my $ptr = zeroes( longlong, 1 );
                my $lut = sequence(byte, 255)->slice("*3,:");
                _pdl_to_gd_image_lut( $pdl, $lut, $ptr );
#		print STDERR "in new (no lut), setting IMG_PTR to " . $ptr->at(0) . "\n";
                $self->{IMG_PTR} = $ptr->at(0);
                $ptr = null;
                die "$sub: _pdl_to_gd_image_lut() failed!\n"
                    if( $self->{IMG_PTR} == 0 );
            }
        }
        elsif( $num_dims == 3 )
        {
            my $ptr = zeroes( longlong, 1 );
            _pdl_to_gd_image_true( $pdl, $ptr );
#	    print STDERR "in new (ndims=3), setting IMG_PTR to " . $ptr->at(0) . "\n";
            $self->{IMG_PTR} = $ptr->at(0);
            $ptr = null;
            die "$sub: _pdl_to_gd_image_true() failed!\n"
                if( $self->{IMG_PTR} == 0 );
        }
        else
        {
            die "Can't create a PDL::IO::GD from a PDL with bad dims!\n";
        }
    }
    elsif( exists( $options->{filename} ) )
    {   # Create it from a file:

        if( !defined $options->{filename} ) {
          die "PDL::IO::GD::new got an undefined filename. Giving up.\n";
        }

        # Figure out what type of file it is:
        $self->{input_type} = _id_image_file( $options->{filename} )
            or die "$sub: Can't determine image type of filename => \'$options->{filename}\'!\n";
        
        # Read in the file:
        $self->{IMG_PTR} = _img_ptr_from_file( $options->{filename}, $self->{input_type} )
            or die "$sub: Can't read in the input file!\n";
    }
    elsif( defined( $options->{x} ) && defined( $options->{y} ) )
    {   # Create an empty image:
        my $done = 0;
        if( defined( $options->{true_color} ) )
        {
            if( $options->{true_color} )
            {   # Create an empty true color image:
                $self->{IMG_PTR} = _gdImageCreateTrueColor( $options->{x}, $options->{y} );
                die "$sub: _gdImageCreateTrueColor() failed!\n"
                    if( $self->{IMG_PTR} == 0 );
                $done = 1;
            }
        }
        unless( $done )
        {   # Create an empty palette image:
            $self->{IMG_PTR} = _gdImageCreatePalette( $options->{x}, $options->{y} );
            die "$sub: _gdImageCreatePalette() failed!\n"
                if( $self->{IMG_PTR} == 0 );
        }
    }
    elsif( defined( $options->{data} ) )
    {   # Create an image from the given image data:
    
        # Figure out what type of file it is:
        if( defined( $options->{type} ) && 
            (      $options->{type} eq 'jpg'
                || $options->{type} eq 'png'
                || $options->{type} eq 'gif'
                || $options->{type} eq 'wbmp'
                || $options->{type} eq 'gd'
                || $options->{type} eq 'gd2' ) )
        {
            $self->{input_type} = $options->{type};
        }
        else
        {
            $self->{input_type} = _id_image_data( $options->{data} )
                or die "$sub: Can't determine image type given data!\n";
        }
        
        # Load the data:
        $self->{IMG_PTR} = _img_ptr_from_data( $options->{data}, $self->{input_type} )
            or die "$sub: Can't load the input image data!\n";
    }
    
    # Bless and return:
    #
    bless ($self, $class);    
    return $self;
} # End of new()...

=head2 to_pdl

When you're done playing with your GDImage and want a piddle back, use this function to return one.

=cut


sub to_pdl
{
    my $self = shift;

    my $sub = _pkg_name( "to_pdl" );
    
    my $x = $self->gdImageSX();
    my $y = $self->gdImageSY();
    
    if( $self->gdImageTrueColor() )
    {
        my $pdl = zeroes(byte, $x, $y, 3);
        _gd_image_to_pdl_true( $pdl, $self->{IMG_PTR} );
        return $pdl;
    }
    
    my $pdl = zeroes(byte, $x, $y);
    _gd_image_to_pdl( $pdl, $self->{IMG_PTR} );
    return $pdl;
} # End of to_pdl()...

=head2 apply_lut( $lut(piddle) )

Does a $im->ColorAllocate() for and entire LUT piddle at once.

The LUT piddle format is the same as for the general interface above.

=cut


sub apply_lut
{
    my $self = shift;
    my $lut = shift;
    
    # Let the PDL threading engine sort this out:
    $self->ColorAllocates( $lut->slice("(0),:"), $lut->slice("(1),:"), $lut->slice("(2),:") );
} # End of apply_lut()...

sub DESTROY
{
    my $self = shift;
    my $sub = _pkg_name( "DESTROY" );
 
    #print STDERR sprintf("$sub: destroying gdImagePtr: 0x%p (%d) (%ld) (%lld)!\n", $self->{IMG_PTR}, $self->{IMG_PTR},$self->{IMG_PTR},$self->{IMG_PTR});
    
    if( defined( $self->{IMG_PTR} ) )
    {
        _gdImageDestroy( $self->{IMG_PTR} );
        delete( $self->{IMG_PTR} );
    }
} # End of DESTROY()...

=head2 WARNING:

All of the docs below this point are auto-generated (not to mention the actual code), 
so read with a grain of salt, and B<always> check the main GD documentation about how 
that function works and what it does.

=cut



=head2 write_Png

$image->write_Png( $filename )

=cut


sub write_Png
{
    my $self = shift;
    return _gdImagePng ( $self->{IMG_PTR}, @_ );
} # End of write_Png()...


=head2 write_PngEx

$image->write_PngEx( $filename, $level )

=cut


sub write_PngEx
{
    my $self = shift;
    return _gdImagePngEx ( $self->{IMG_PTR}, @_ );
} # End of write_PngEx()...


=head2 write_WBMP

$image->write_WBMP( $fg, $filename )

=cut


sub write_WBMP
{
    my $self = shift;
    return _gdImageWBMP ( $self->{IMG_PTR}, @_ );
} # End of write_WBMP()...


=head2 write_Jpeg

$image->write_Jpeg( $filename, $quality )

=cut


sub write_Jpeg
{
    my $self = shift;
    return _gdImageJpeg ( $self->{IMG_PTR}, @_ );
} # End of write_Jpeg()...


=head2 write_Gd

$image->write_Gd( $filename )

=cut


sub write_Gd
{
    my $self = shift;
    return _gdImageGd ( $self->{IMG_PTR}, @_ );
} # End of write_Gd()...


=head2 write_Gd2

$image->write_Gd2( $filename, $cs, $fmt )

=cut


sub write_Gd2
{
    my $self = shift;
    return _gdImageGd2 ( $self->{IMG_PTR}, @_ );
} # End of write_Gd2()...


=head2 write_Gif

$image->write_Gif( $filename )

=cut


sub write_Gif
{
    my $self = shift;
    return _gdImageGif ( $self->{IMG_PTR}, @_ );
} # End of write_Gif()...


=head2 get_Png_data

$image->get_Png_data(  )

=cut


sub get_Png_data
{
    my $self = shift;
    return _gdImagePngPtr ( $self->{IMG_PTR}, @_ );
} # End of get_Png_data()...


=head2 get_PngEx_data

$image->get_PngEx_data( $level )

=cut


sub get_PngEx_data
{
    my $self = shift;
    return _gdImagePngPtrEx ( $self->{IMG_PTR}, @_ );
} # End of get_PngEx_data()...


=head2 get_WBMP_data

$image->get_WBMP_data( $fg )

=cut


sub get_WBMP_data
{
    my $self = shift;
    return _gdImageWBMPPtr ( $self->{IMG_PTR}, @_ );
} # End of get_WBMP_data()...


=head2 get_Jpeg_data

$image->get_Jpeg_data( $quality )

=cut


sub get_Jpeg_data
{
    my $self = shift;
    return _gdImageJpegPtr ( $self->{IMG_PTR}, @_ );
} # End of get_Jpeg_data()...


=head2 get_Gd_data

$image->get_Gd_data(  )

=cut


sub get_Gd_data
{
    my $self = shift;
    return _gdImageGdPtr ( $self->{IMG_PTR}, @_ );
} # End of get_Gd_data()...


=head2 get_Gd2_data

$image->get_Gd2_data( $cs, $fmt )

=cut


sub get_Gd2_data
{
    my $self = shift;
    return _gdImageGd2Ptr ( $self->{IMG_PTR}, @_ );
} # End of get_Gd2_data()...


=head2 SetPixel

$image->SetPixel( $x, $y, $color )

Alias for gdImageSetPixel.

=cut


sub SetPixel
{
    return gdImageSetPixel ( @_ );
} # End of SetPixel()...


=head2 gdImageSetPixel

$image->gdImageSetPixel( $x, $y, $color )

=cut


sub gdImageSetPixel
{
    my $self = shift;
    return _gdImageSetPixel ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetPixel()...


=head2 GetPixel

$image->GetPixel( $x, $y )

Alias for gdImageGetPixel.

=cut


sub GetPixel
{
    return gdImageGetPixel ( @_ );
} # End of GetPixel()...


=head2 gdImageGetPixel

$image->gdImageGetPixel( $x, $y )

=cut


sub gdImageGetPixel
{
    my $self = shift;
    return _gdImageGetPixel ( $self->{IMG_PTR}, @_ );
} # End of gdImageGetPixel()...


=head2 AABlend

$image->AABlend(  )

Alias for gdImageAABlend.

=cut


sub AABlend
{
    return gdImageAABlend ( @_ );
} # End of AABlend()...


=head2 gdImageAABlend

$image->gdImageAABlend(  )

=cut


sub gdImageAABlend
{
    my $self = shift;
    return _gdImageAABlend ( $self->{IMG_PTR}, @_ );
} # End of gdImageAABlend()...


=head2 Line

$image->Line( $x1, $y1, $x2, $y2, $color )

Alias for gdImageLine.

=cut


sub Line
{
    return gdImageLine ( @_ );
} # End of Line()...


=head2 gdImageLine

$image->gdImageLine( $x1, $y1, $x2, $y2, $color )

=cut


sub gdImageLine
{
    my $self = shift;
    return _gdImageLine ( $self->{IMG_PTR}, @_ );
} # End of gdImageLine()...


=head2 DashedLine

$image->DashedLine( $x1, $y1, $x2, $y2, $color )

Alias for gdImageDashedLine.

=cut


sub DashedLine
{
    return gdImageDashedLine ( @_ );
} # End of DashedLine()...


=head2 gdImageDashedLine

$image->gdImageDashedLine( $x1, $y1, $x2, $y2, $color )

=cut


sub gdImageDashedLine
{
    my $self = shift;
    return _gdImageDashedLine ( $self->{IMG_PTR}, @_ );
} # End of gdImageDashedLine()...


=head2 Rectangle

$image->Rectangle( $x1, $y1, $x2, $y2, $color )

Alias for gdImageRectangle.

=cut


sub Rectangle
{
    return gdImageRectangle ( @_ );
} # End of Rectangle()...


=head2 gdImageRectangle

$image->gdImageRectangle( $x1, $y1, $x2, $y2, $color )

=cut


sub gdImageRectangle
{
    my $self = shift;
    return _gdImageRectangle ( $self->{IMG_PTR}, @_ );
} # End of gdImageRectangle()...


=head2 FilledRectangle

$image->FilledRectangle( $x1, $y1, $x2, $y2, $color )

Alias for gdImageFilledRectangle.

=cut


sub FilledRectangle
{
    return gdImageFilledRectangle ( @_ );
} # End of FilledRectangle()...


=head2 gdImageFilledRectangle

$image->gdImageFilledRectangle( $x1, $y1, $x2, $y2, $color )

=cut


sub gdImageFilledRectangle
{
    my $self = shift;
    return _gdImageFilledRectangle ( $self->{IMG_PTR}, @_ );
} # End of gdImageFilledRectangle()...


=head2 SetClip

$image->SetClip( $x1, $y1, $x2, $y2 )

Alias for gdImageSetClip.

=cut


sub SetClip
{
    return gdImageSetClip ( @_ );
} # End of SetClip()...


=head2 gdImageSetClip

$image->gdImageSetClip( $x1, $y1, $x2, $y2 )

=cut


sub gdImageSetClip
{
    my $self = shift;
    return _gdImageSetClip ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetClip()...


=head2 GetClip

$image->GetClip( $x1P, $y1P, $x2P, $y2P )

Alias for gdImageGetClip.

=cut


sub GetClip
{
    return gdImageGetClip ( @_ );
} # End of GetClip()...


=head2 gdImageGetClip

$image->gdImageGetClip( $x1P, $y1P, $x2P, $y2P )

=cut


sub gdImageGetClip
{
    my $self = shift;
    return _gdImageGetClip ( $self->{IMG_PTR}, @_ );
} # End of gdImageGetClip()...


=head2 BoundsSafe

$image->BoundsSafe( $x, $y )

Alias for gdImageBoundsSafe.

=cut


sub BoundsSafe
{
    return gdImageBoundsSafe ( @_ );
} # End of BoundsSafe()...


=head2 gdImageBoundsSafe

$image->gdImageBoundsSafe( $x, $y )

=cut


sub gdImageBoundsSafe
{
    my $self = shift;
    return _gdImageBoundsSafe ( $self->{IMG_PTR}, @_ );
} # End of gdImageBoundsSafe()...


=head2 Char

$image->Char( $f, $x, $y, $c, $color )

Alias for gdImageChar.

=cut


sub Char
{
    return gdImageChar ( @_ );
} # End of Char()...


=head2 gdImageChar

$image->gdImageChar( $f, $x, $y, $c, $color )

=cut


sub gdImageChar
{
    my $self = shift;
    return _gdImageChar ( $self->{IMG_PTR}, @_ );
} # End of gdImageChar()...


=head2 CharUp

$image->CharUp( $f, $x, $y, $c, $color )

Alias for gdImageCharUp.

=cut


sub CharUp
{
    return gdImageCharUp ( @_ );
} # End of CharUp()...


=head2 gdImageCharUp

$image->gdImageCharUp( $f, $x, $y, $c, $color )

=cut


sub gdImageCharUp
{
    my $self = shift;
    return _gdImageCharUp ( $self->{IMG_PTR}, @_ );
} # End of gdImageCharUp()...


=head2 String

$image->String( $f, $x, $y, $s, $color )

Alias for gdImageString.

=cut


sub String
{
    return gdImageString ( @_ );
} # End of String()...


=head2 gdImageString

$image->gdImageString( $f, $x, $y, $s, $color )

=cut


sub gdImageString
{
    my $self = shift;
    return _gdImageString ( $self->{IMG_PTR}, @_ );
} # End of gdImageString()...


=head2 StringUp

$image->StringUp( $f, $x, $y, $s, $color )

Alias for gdImageStringUp.

=cut


sub StringUp
{
    return gdImageStringUp ( @_ );
} # End of StringUp()...


=head2 gdImageStringUp

$image->gdImageStringUp( $f, $x, $y, $s, $color )

=cut


sub gdImageStringUp
{
    my $self = shift;
    return _gdImageStringUp ( $self->{IMG_PTR}, @_ );
} # End of gdImageStringUp()...


=head2 String16

$image->String16( $f, $x, $y, $s, $color )

Alias for gdImageString16.

=cut


sub String16
{
    return gdImageString16 ( @_ );
} # End of String16()...


=head2 gdImageString16

$image->gdImageString16( $f, $x, $y, $s, $color )

=cut


sub gdImageString16
{
    my $self = shift;
    return _gdImageString16 ( $self->{IMG_PTR}, @_ );
} # End of gdImageString16()...


=head2 StringUp16

$image->StringUp16( $f, $x, $y, $s, $color )

Alias for gdImageStringUp16.

=cut


sub StringUp16
{
    return gdImageStringUp16 ( @_ );
} # End of StringUp16()...


=head2 gdImageStringUp16

$image->gdImageStringUp16( $f, $x, $y, $s, $color )

=cut


sub gdImageStringUp16
{
    my $self = shift;
    return _gdImageStringUp16 ( $self->{IMG_PTR}, @_ );
} # End of gdImageStringUp16()...


=head2 Polygon

$image->Polygon( $p, $n, $c )

Alias for gdImagePolygon.

=cut


sub Polygon
{
    return gdImagePolygon ( @_ );
} # End of Polygon()...


=head2 gdImagePolygon

$image->gdImagePolygon( $p, $n, $c )

=cut


sub gdImagePolygon
{
    my $self = shift;
    return _gdImagePolygon ( $self->{IMG_PTR}, @_ );
} # End of gdImagePolygon()...


=head2 FilledPolygon

$image->FilledPolygon( $p, $n, $c )

Alias for gdImageFilledPolygon.

=cut


sub FilledPolygon
{
    return gdImageFilledPolygon ( @_ );
} # End of FilledPolygon()...


=head2 gdImageFilledPolygon

$image->gdImageFilledPolygon( $p, $n, $c )

=cut


sub gdImageFilledPolygon
{
    my $self = shift;
    return _gdImageFilledPolygon ( $self->{IMG_PTR}, @_ );
} # End of gdImageFilledPolygon()...


=head2 ColorAllocate

$image->ColorAllocate( $r, $g, $b )

Alias for gdImageColorAllocate.

=cut


sub ColorAllocate
{
    return gdImageColorAllocate ( @_ );
} # End of ColorAllocate()...


=head2 gdImageColorAllocate

$image->gdImageColorAllocate( $r, $g, $b )

=cut


sub gdImageColorAllocate
{
    my $self = shift;
    return _gdImageColorAllocate ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorAllocate()...


=head2 ColorAllocateAlpha

$image->ColorAllocateAlpha( $r, $g, $b, $a )

Alias for gdImageColorAllocateAlpha.

=cut


sub ColorAllocateAlpha
{
    return gdImageColorAllocateAlpha ( @_ );
} # End of ColorAllocateAlpha()...


=head2 gdImageColorAllocateAlpha

$image->gdImageColorAllocateAlpha( $r, $g, $b, $a )

=cut


sub gdImageColorAllocateAlpha
{
    my $self = shift;
    return _gdImageColorAllocateAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorAllocateAlpha()...


=head2 ColorClosest

$image->ColorClosest( $r, $g, $b )

Alias for gdImageColorClosest.

=cut


sub ColorClosest
{
    return gdImageColorClosest ( @_ );
} # End of ColorClosest()...


=head2 gdImageColorClosest

$image->gdImageColorClosest( $r, $g, $b )

=cut


sub gdImageColorClosest
{
    my $self = shift;
    return _gdImageColorClosest ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorClosest()...


=head2 ColorClosestAlpha

$image->ColorClosestAlpha( $r, $g, $b, $a )

Alias for gdImageColorClosestAlpha.

=cut


sub ColorClosestAlpha
{
    return gdImageColorClosestAlpha ( @_ );
} # End of ColorClosestAlpha()...


=head2 gdImageColorClosestAlpha

$image->gdImageColorClosestAlpha( $r, $g, $b, $a )

=cut


sub gdImageColorClosestAlpha
{
    my $self = shift;
    return _gdImageColorClosestAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorClosestAlpha()...


=head2 ColorClosestHWB

$image->ColorClosestHWB( $r, $g, $b )

Alias for gdImageColorClosestHWB.

=cut


sub ColorClosestHWB
{
    return gdImageColorClosestHWB ( @_ );
} # End of ColorClosestHWB()...


=head2 gdImageColorClosestHWB

$image->gdImageColorClosestHWB( $r, $g, $b )

=cut


sub gdImageColorClosestHWB
{
    my $self = shift;
    return _gdImageColorClosestHWB ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorClosestHWB()...


=head2 ColorExact

$image->ColorExact( $r, $g, $b )

Alias for gdImageColorExact.

=cut


sub ColorExact
{
    return gdImageColorExact ( @_ );
} # End of ColorExact()...


=head2 gdImageColorExact

$image->gdImageColorExact( $r, $g, $b )

=cut


sub gdImageColorExact
{
    my $self = shift;
    return _gdImageColorExact ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorExact()...


=head2 ColorExactAlpha

$image->ColorExactAlpha( $r, $g, $b, $a )

Alias for gdImageColorExactAlpha.

=cut


sub ColorExactAlpha
{
    return gdImageColorExactAlpha ( @_ );
} # End of ColorExactAlpha()...


=head2 gdImageColorExactAlpha

$image->gdImageColorExactAlpha( $r, $g, $b, $a )

=cut


sub gdImageColorExactAlpha
{
    my $self = shift;
    return _gdImageColorExactAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorExactAlpha()...


=head2 ColorResolve

$image->ColorResolve( $r, $g, $b )

Alias for gdImageColorResolve.

=cut


sub ColorResolve
{
    return gdImageColorResolve ( @_ );
} # End of ColorResolve()...


=head2 gdImageColorResolve

$image->gdImageColorResolve( $r, $g, $b )

=cut


sub gdImageColorResolve
{
    my $self = shift;
    return _gdImageColorResolve ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorResolve()...


=head2 ColorResolveAlpha

$image->ColorResolveAlpha( $r, $g, $b, $a )

Alias for gdImageColorResolveAlpha.

=cut


sub ColorResolveAlpha
{
    return gdImageColorResolveAlpha ( @_ );
} # End of ColorResolveAlpha()...


=head2 gdImageColorResolveAlpha

$image->gdImageColorResolveAlpha( $r, $g, $b, $a )

=cut


sub gdImageColorResolveAlpha
{
    my $self = shift;
    return _gdImageColorResolveAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorResolveAlpha()...


=head2 ColorDeallocate

$image->ColorDeallocate( $color )

Alias for gdImageColorDeallocate.

=cut


sub ColorDeallocate
{
    return gdImageColorDeallocate ( @_ );
} # End of ColorDeallocate()...


=head2 gdImageColorDeallocate

$image->gdImageColorDeallocate( $color )

=cut


sub gdImageColorDeallocate
{
    my $self = shift;
    return _gdImageColorDeallocate ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorDeallocate()...


=head2 TrueColorToPalette

$image->TrueColorToPalette( $ditherFlag, $colorsWanted )

Alias for gdImageTrueColorToPalette.

=cut


sub TrueColorToPalette
{
    return gdImageTrueColorToPalette ( @_ );
} # End of TrueColorToPalette()...


=head2 gdImageTrueColorToPalette

$image->gdImageTrueColorToPalette( $ditherFlag, $colorsWanted )

=cut


sub gdImageTrueColorToPalette
{
    my $self = shift;
    return _gdImageTrueColorToPalette ( $self->{IMG_PTR}, @_ );
} # End of gdImageTrueColorToPalette()...


=head2 ColorTransparent

$image->ColorTransparent( $color )

Alias for gdImageColorTransparent.

=cut


sub ColorTransparent
{
    return gdImageColorTransparent ( @_ );
} # End of ColorTransparent()...


=head2 gdImageColorTransparent

$image->gdImageColorTransparent( $color )

=cut


sub gdImageColorTransparent
{
    my $self = shift;
    return _gdImageColorTransparent ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorTransparent()...


=head2 FilledArc

$image->FilledArc( $cx, $cy, $w, $h, $s, $e, $color, $style )

Alias for gdImageFilledArc.

=cut


sub FilledArc
{
    return gdImageFilledArc ( @_ );
} # End of FilledArc()...


=head2 gdImageFilledArc

$image->gdImageFilledArc( $cx, $cy, $w, $h, $s, $e, $color, $style )

=cut


sub gdImageFilledArc
{
    my $self = shift;
    return _gdImageFilledArc ( $self->{IMG_PTR}, @_ );
} # End of gdImageFilledArc()...


=head2 Arc

$image->Arc( $cx, $cy, $w, $h, $s, $e, $color )

Alias for gdImageArc.

=cut


sub Arc
{
    return gdImageArc ( @_ );
} # End of Arc()...


=head2 gdImageArc

$image->gdImageArc( $cx, $cy, $w, $h, $s, $e, $color )

=cut


sub gdImageArc
{
    my $self = shift;
    return _gdImageArc ( $self->{IMG_PTR}, @_ );
} # End of gdImageArc()...


=head2 FilledEllipse

$image->FilledEllipse( $cx, $cy, $w, $h, $color )

Alias for gdImageFilledEllipse.

=cut


sub FilledEllipse
{
    return gdImageFilledEllipse ( @_ );
} # End of FilledEllipse()...


=head2 gdImageFilledEllipse

$image->gdImageFilledEllipse( $cx, $cy, $w, $h, $color )

=cut


sub gdImageFilledEllipse
{
    my $self = shift;
    return _gdImageFilledEllipse ( $self->{IMG_PTR}, @_ );
} # End of gdImageFilledEllipse()...


=head2 FillToBorder

$image->FillToBorder( $x, $y, $border, $color )

Alias for gdImageFillToBorder.

=cut


sub FillToBorder
{
    return gdImageFillToBorder ( @_ );
} # End of FillToBorder()...


=head2 gdImageFillToBorder

$image->gdImageFillToBorder( $x, $y, $border, $color )

=cut


sub gdImageFillToBorder
{
    my $self = shift;
    return _gdImageFillToBorder ( $self->{IMG_PTR}, @_ );
} # End of gdImageFillToBorder()...


=head2 Fill

$image->Fill( $x, $y, $color )

Alias for gdImageFill.

=cut


sub Fill
{
    return gdImageFill ( @_ );
} # End of Fill()...


=head2 gdImageFill

$image->gdImageFill( $x, $y, $color )

=cut


sub gdImageFill
{
    my $self = shift;
    return _gdImageFill ( $self->{IMG_PTR}, @_ );
} # End of gdImageFill()...


=head2 CopyRotated

$image->CopyRotated( $dstX, $dstY, $srcX, $srcY, $srcWidth, $srcHeight, $angle )

Alias for gdImageCopyRotated.

=cut


sub CopyRotated
{
    return gdImageCopyRotated ( @_ );
} # End of CopyRotated()...


=head2 gdImageCopyRotated

$image->gdImageCopyRotated( $dstX, $dstY, $srcX, $srcY, $srcWidth, $srcHeight, $angle )

=cut


sub gdImageCopyRotated
{
    my $self = shift;
    return _gdImageCopyRotated ( $self->{IMG_PTR}, @_ );
} # End of gdImageCopyRotated()...


=head2 SetBrush

$image->SetBrush(  )

Alias for gdImageSetBrush.

=cut


sub SetBrush
{
    return gdImageSetBrush ( @_ );
} # End of SetBrush()...


=head2 gdImageSetBrush

$image->gdImageSetBrush(  )

=cut


sub gdImageSetBrush
{
    my $self = shift;
    return _gdImageSetBrush ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetBrush()...


=head2 SetTile

$image->SetTile(  )

Alias for gdImageSetTile.

=cut


sub SetTile
{
    return gdImageSetTile ( @_ );
} # End of SetTile()...


=head2 gdImageSetTile

$image->gdImageSetTile(  )

=cut


sub gdImageSetTile
{
    my $self = shift;
    return _gdImageSetTile ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetTile()...


=head2 SetAntiAliased

$image->SetAntiAliased( $c )

Alias for gdImageSetAntiAliased.

=cut


sub SetAntiAliased
{
    return gdImageSetAntiAliased ( @_ );
} # End of SetAntiAliased()...


=head2 gdImageSetAntiAliased

$image->gdImageSetAntiAliased( $c )

=cut


sub gdImageSetAntiAliased
{
    my $self = shift;
    return _gdImageSetAntiAliased ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetAntiAliased()...


=head2 SetAntiAliasedDontBlend

$image->SetAntiAliasedDontBlend( $c, $dont_blend )

Alias for gdImageSetAntiAliasedDontBlend.

=cut


sub SetAntiAliasedDontBlend
{
    return gdImageSetAntiAliasedDontBlend ( @_ );
} # End of SetAntiAliasedDontBlend()...


=head2 gdImageSetAntiAliasedDontBlend

$image->gdImageSetAntiAliasedDontBlend( $c, $dont_blend )

=cut


sub gdImageSetAntiAliasedDontBlend
{
    my $self = shift;
    return _gdImageSetAntiAliasedDontBlend ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetAntiAliasedDontBlend()...


=head2 SetStyle

$image->SetStyle( $style, $noOfPixels )

Alias for gdImageSetStyle.

=cut


sub SetStyle
{
    return gdImageSetStyle ( @_ );
} # End of SetStyle()...


=head2 gdImageSetStyle

$image->gdImageSetStyle( $style, $noOfPixels )

=cut


sub gdImageSetStyle
{
    my $self = shift;
    return _gdImageSetStyle ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetStyle()...


=head2 SetThickness

$image->SetThickness( $thickness )

Alias for gdImageSetThickness.

=cut


sub SetThickness
{
    return gdImageSetThickness ( @_ );
} # End of SetThickness()...


=head2 gdImageSetThickness

$image->gdImageSetThickness( $thickness )

=cut


sub gdImageSetThickness
{
    my $self = shift;
    return _gdImageSetThickness ( $self->{IMG_PTR}, @_ );
} # End of gdImageSetThickness()...


=head2 Interlace

$image->Interlace( $interlaceArg )

Alias for gdImageInterlace.

=cut


sub Interlace
{
    return gdImageInterlace ( @_ );
} # End of Interlace()...


=head2 gdImageInterlace

$image->gdImageInterlace( $interlaceArg )

=cut


sub gdImageInterlace
{
    my $self = shift;
    return _gdImageInterlace ( $self->{IMG_PTR}, @_ );
} # End of gdImageInterlace()...


=head2 AlphaBlending

$image->AlphaBlending( $alphaBlendingArg )

Alias for gdImageAlphaBlending.

=cut


sub AlphaBlending
{
    return gdImageAlphaBlending ( @_ );
} # End of AlphaBlending()...


=head2 gdImageAlphaBlending

$image->gdImageAlphaBlending( $alphaBlendingArg )

=cut


sub gdImageAlphaBlending
{
    my $self = shift;
    return _gdImageAlphaBlending ( $self->{IMG_PTR}, @_ );
} # End of gdImageAlphaBlending()...


=head2 SaveAlpha

$image->SaveAlpha( $saveAlphaArg )

Alias for gdImageSaveAlpha.

=cut


sub SaveAlpha
{
    return gdImageSaveAlpha ( @_ );
} # End of SaveAlpha()...


=head2 gdImageSaveAlpha

$image->gdImageSaveAlpha( $saveAlphaArg )

=cut


sub gdImageSaveAlpha
{
    my $self = shift;
    return _gdImageSaveAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageSaveAlpha()...


=head2 TrueColor

$image->TrueColor(  )

Alias for gdImageTrueColor.

=cut


sub TrueColor
{
    return gdImageTrueColor ( @_ );
} # End of TrueColor()...


=head2 gdImageTrueColor

$image->gdImageTrueColor(  )

=cut


sub gdImageTrueColor
{
    my $self = shift;
    return _gdImageTrueColor ( $self->{IMG_PTR}, @_ );
} # End of gdImageTrueColor()...


=head2 ColorsTotal

$image->ColorsTotal(  )

Alias for gdImageColorsTotal.

=cut


sub ColorsTotal
{
    return gdImageColorsTotal ( @_ );
} # End of ColorsTotal()...


=head2 gdImageColorsTotal

$image->gdImageColorsTotal(  )

=cut


sub gdImageColorsTotal
{
    my $self = shift;
    return _gdImageColorsTotal ( $self->{IMG_PTR}, @_ );
} # End of gdImageColorsTotal()...


=head2 Red

$image->Red( $c )

Alias for gdImageRed.

=cut


sub Red
{
    return gdImageRed ( @_ );
} # End of Red()...


=head2 gdImageRed

$image->gdImageRed( $c )

=cut


sub gdImageRed
{
    my $self = shift;
    return _gdImageRed ( $self->{IMG_PTR}, @_ );
} # End of gdImageRed()...


=head2 Green

$image->Green( $c )

Alias for gdImageGreen.

=cut


sub Green
{
    return gdImageGreen ( @_ );
} # End of Green()...


=head2 gdImageGreen

$image->gdImageGreen( $c )

=cut


sub gdImageGreen
{
    my $self = shift;
    return _gdImageGreen ( $self->{IMG_PTR}, @_ );
} # End of gdImageGreen()...


=head2 Blue

$image->Blue( $c )

Alias for gdImageBlue.

=cut


sub Blue
{
    return gdImageBlue ( @_ );
} # End of Blue()...


=head2 gdImageBlue

$image->gdImageBlue( $c )

=cut


sub gdImageBlue
{
    my $self = shift;
    return _gdImageBlue ( $self->{IMG_PTR}, @_ );
} # End of gdImageBlue()...


=head2 Alpha

$image->Alpha( $c )

Alias for gdImageAlpha.

=cut


sub Alpha
{
    return gdImageAlpha ( @_ );
} # End of Alpha()...


=head2 gdImageAlpha

$image->gdImageAlpha( $c )

=cut


sub gdImageAlpha
{
    my $self = shift;
    return _gdImageAlpha ( $self->{IMG_PTR}, @_ );
} # End of gdImageAlpha()...


=head2 GetTransparent

$image->GetTransparent(  )

Alias for gdImageGetTransparent.

=cut


sub GetTransparent
{
    return gdImageGetTransparent ( @_ );
} # End of GetTransparent()...


=head2 gdImageGetTransparent

$image->gdImageGetTransparent(  )

=cut


sub gdImageGetTransparent
{
    my $self = shift;
    return _gdImageGetTransparent ( $self->{IMG_PTR}, @_ );
} # End of gdImageGetTransparent()...


=head2 GetInterlaced

$image->GetInterlaced(  )

Alias for gdImageGetInterlaced.

=cut


sub GetInterlaced
{
    return gdImageGetInterlaced ( @_ );
} # End of GetInterlaced()...


=head2 gdImageGetInterlaced

$image->gdImageGetInterlaced(  )

=cut


sub gdImageGetInterlaced
{
    my $self = shift;
    return _gdImageGetInterlaced ( $self->{IMG_PTR}, @_ );
} # End of gdImageGetInterlaced()...


=head2 SX

$image->SX(  )

Alias for gdImageSX.

=cut


sub SX
{
    return gdImageSX ( @_ );
} # End of SX()...


=head2 gdImageSX

$image->gdImageSX(  )

=cut


sub gdImageSX
{
    my $self = shift;
    return _gdImageSX ( $self->{IMG_PTR}, @_ );
} # End of gdImageSX()...


=head2 SY

$image->SY(  )

Alias for gdImageSY.

=cut


sub SY
{
    return gdImageSY ( @_ );
} # End of SY()...


=head2 gdImageSY

$image->gdImageSY(  )

=cut


sub gdImageSY
{
    my $self = shift;
    return _gdImageSY ( $self->{IMG_PTR}, @_ );
} # End of gdImageSY()...


=head2 ColorAllocates

$image->ColorAllocates( $r(pdl), $g(pdl), $b(pdl) )

Alias for gdImageColorAllocates.

=cut


sub ColorAllocates
{
    return gdImageColorAllocates ( @_ );
} # End of ColorAllocates()...


=head2 gdImageColorAllocates

$image->gdImageColorAllocates( $r(pdl), $g(pdl), $b(pdl) )

=cut


sub gdImageColorAllocates
{
    my $self = shift;
    return _gdImageColorAllocates ( @_, $self->{IMG_PTR} );
} # End of gdImageColorAllocates()...


=head2 ColorAllocateAlphas

$image->ColorAllocateAlphas( $r(pdl), $g(pdl), $b(pdl), $a(pdl) )

Alias for gdImageColorAllocateAlphas.

=cut


sub ColorAllocateAlphas
{
    return gdImageColorAllocateAlphas ( @_ );
} # End of ColorAllocateAlphas()...


=head2 gdImageColorAllocateAlphas

$image->gdImageColorAllocateAlphas( $r(pdl), $g(pdl), $b(pdl), $a(pdl) )

=cut


sub gdImageColorAllocateAlphas
{
    my $self = shift;
    return _gdImageColorAllocateAlphas ( @_, $self->{IMG_PTR} );
} # End of gdImageColorAllocateAlphas()...


=head2 SetPixels

$image->SetPixels( $x(pdl), $y(pdl), $color(pdl) )

Alias for gdImageSetPixels.

=cut


sub SetPixels
{
    return gdImageSetPixels ( @_ );
} # End of SetPixels()...


=head2 gdImageSetPixels

$image->gdImageSetPixels( $x(pdl), $y(pdl), $color(pdl) )

=cut


sub gdImageSetPixels
{
    my $self = shift;
    return _gdImageSetPixels ( @_, $self->{IMG_PTR} );
} # End of gdImageSetPixels()...


=head2 Lines

$image->Lines( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

Alias for gdImageLines.

=cut


sub Lines
{
    return gdImageLines ( @_ );
} # End of Lines()...


=head2 gdImageLines

$image->gdImageLines( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

=cut


sub gdImageLines
{
    my $self = shift;
    return _gdImageLines ( @_, $self->{IMG_PTR} );
} # End of gdImageLines()...


=head2 DashedLines

$image->DashedLines( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

Alias for gdImageDashedLines.

=cut


sub DashedLines
{
    return gdImageDashedLines ( @_ );
} # End of DashedLines()...


=head2 gdImageDashedLines

$image->gdImageDashedLines( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

=cut


sub gdImageDashedLines
{
    my $self = shift;
    return _gdImageDashedLines ( @_, $self->{IMG_PTR} );
} # End of gdImageDashedLines()...


=head2 Rectangles

$image->Rectangles( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

Alias for gdImageRectangles.

=cut


sub Rectangles
{
    return gdImageRectangles ( @_ );
} # End of Rectangles()...


=head2 gdImageRectangles

$image->gdImageRectangles( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

=cut


sub gdImageRectangles
{
    my $self = shift;
    return _gdImageRectangles ( @_, $self->{IMG_PTR} );
} # End of gdImageRectangles()...


=head2 FilledRectangles

$image->FilledRectangles( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

Alias for gdImageFilledRectangles.

=cut


sub FilledRectangles
{
    return gdImageFilledRectangles ( @_ );
} # End of FilledRectangles()...


=head2 gdImageFilledRectangles

$image->gdImageFilledRectangles( $x1(pdl), $y1(pdl), $x2(pdl), $y2(pdl), $color(pdl) )

=cut


sub gdImageFilledRectangles
{
    my $self = shift;
    return _gdImageFilledRectangles ( @_, $self->{IMG_PTR} );
} # End of gdImageFilledRectangles()...


=head2 FilledArcs

$image->FilledArcs( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $s(pdl), $e(pdl), $color(pdl), $style(pdl) )

Alias for gdImageFilledArcs.

=cut


sub FilledArcs
{
    return gdImageFilledArcs ( @_ );
} # End of FilledArcs()...


=head2 gdImageFilledArcs

$image->gdImageFilledArcs( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $s(pdl), $e(pdl), $color(pdl), $style(pdl) )

=cut


sub gdImageFilledArcs
{
    my $self = shift;
    return _gdImageFilledArcs ( @_, $self->{IMG_PTR} );
} # End of gdImageFilledArcs()...


=head2 Arcs

$image->Arcs( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $s(pdl), $e(pdl), $color(pdl) )

Alias for gdImageArcs.

=cut


sub Arcs
{
    return gdImageArcs ( @_ );
} # End of Arcs()...


=head2 gdImageArcs

$image->gdImageArcs( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $s(pdl), $e(pdl), $color(pdl) )

=cut


sub gdImageArcs
{
    my $self = shift;
    return _gdImageArcs ( @_, $self->{IMG_PTR} );
} # End of gdImageArcs()...


=head2 FilledEllipses

$image->FilledEllipses( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $color(pdl) )

Alias for gdImageFilledEllipses.

=cut


sub FilledEllipses
{
    return gdImageFilledEllipses ( @_ );
} # End of FilledEllipses()...


=head2 gdImageFilledEllipses

$image->gdImageFilledEllipses( $cx(pdl), $cy(pdl), $w(pdl), $h(pdl), $color(pdl) )

=cut


sub gdImageFilledEllipses
{
    my $self = shift;
    return _gdImageFilledEllipses ( @_, $self->{IMG_PTR} );
} # End of gdImageFilledEllipses()...


=head1 CLASS FUNCTIONS

=cut




=head2 gdImageCopy

gdImageCopy ( $dst(PDL::IO::GD), $src(PDL::IO::GD), $dstX, $dstY, $srcX, $srcY, $w, $h )

=cut


sub gdImageCopy
{
    my $dst = shift;
    my $src = shift;
    my $dstX = shift;
    my $dstY = shift;
    my $srcX = shift;
    my $srcY = shift;
    my $w = shift;
    my $h = shift;

    return _gdImageCopy ( $dst->{IMG_PTR}, $src->{IMG_PTR}, $dstX, $dstY, $srcX, $srcY, $w, $h );
} # End of gdImageCopy()...


=head2 gdImageCopyMerge

gdImageCopyMerge ( $dst(PDL::IO::GD), $src(PDL::IO::GD), $dstX, $dstY, $srcX, $srcY, $w, $h, $pct )

=cut


sub gdImageCopyMerge
{
    my $dst = shift;
    my $src = shift;
    my $dstX = shift;
    my $dstY = shift;
    my $srcX = shift;
    my $srcY = shift;
    my $w = shift;
    my $h = shift;
    my $pct = shift;

    return _gdImageCopyMerge ( $dst->{IMG_PTR}, $src->{IMG_PTR}, $dstX, $dstY, $srcX, $srcY, $w, $h, $pct );
} # End of gdImageCopyMerge()...


=head2 gdImageCopyMergeGray

gdImageCopyMergeGray ( $dst(PDL::IO::GD), $src(PDL::IO::GD), $dstX, $dstY, $srcX, $srcY, $w, $h, $pct )

=cut


sub gdImageCopyMergeGray
{
    my $dst = shift;
    my $src = shift;
    my $dstX = shift;
    my $dstY = shift;
    my $srcX = shift;
    my $srcY = shift;
    my $w = shift;
    my $h = shift;
    my $pct = shift;

    return _gdImageCopyMergeGray ( $dst->{IMG_PTR}, $src->{IMG_PTR}, $dstX, $dstY, $srcX, $srcY, $w, $h, $pct );
} # End of gdImageCopyMergeGray()...


=head2 gdImageCopyResized

gdImageCopyResized ( $dst(PDL::IO::GD), $src(PDL::IO::GD), $dstX, $dstY, $srcX, $srcY, $dstW, $dstH, $srcW, $srcH )

=cut


sub gdImageCopyResized
{
    my $dst = shift;
    my $src = shift;
    my $dstX = shift;
    my $dstY = shift;
    my $srcX = shift;
    my $srcY = shift;
    my $dstW = shift;
    my $dstH = shift;
    my $srcW = shift;
    my $srcH = shift;

    return _gdImageCopyResized ( $dst->{IMG_PTR}, $src->{IMG_PTR}, $dstX, $dstY, $srcX, $srcY, $dstW, $dstH, $srcW, $srcH );
} # End of gdImageCopyResized()...


=head2 gdImageCopyResampled

gdImageCopyResampled ( $dst(PDL::IO::GD), $src(PDL::IO::GD), $dstX, $dstY, $srcX, $srcY, $dstW, $dstH, $srcW, $srcH )

=cut


sub gdImageCopyResampled
{
    my $dst = shift;
    my $src = shift;
    my $dstX = shift;
    my $dstY = shift;
    my $srcX = shift;
    my $srcY = shift;
    my $dstW = shift;
    my $dstH = shift;
    my $srcW = shift;
    my $srcH = shift;

    return _gdImageCopyResampled ( $dst->{IMG_PTR}, $src->{IMG_PTR}, $dstX, $dstY, $srcX, $srcY, $dstW, $dstH, $srcW, $srcH );
} # End of gdImageCopyResampled()...


=head2 gdImageCompare

gdImageCompare ( $im1(PDL::IO::GD), $im2(PDL::IO::GD) )

=cut


sub gdImageCompare
{
    my $im1 = shift;
    my $im2 = shift;

    return _gdImageCompare ( $im1->{IMG_PTR}, $im2->{IMG_PTR} );
} # End of gdImageCompare()...


=head2 gdImagePaletteCopy

gdImagePaletteCopy ( $dst(PDL::IO::GD), $src(PDL::IO::GD) )

=cut


sub gdImagePaletteCopy
{
    my $dst = shift;
    my $src = shift;

    return _gdImagePaletteCopy ( $dst->{IMG_PTR}, $src->{IMG_PTR} );
} # End of gdImagePaletteCopy()...


=head2 StringTTF

$image->StringTTF( $brect, $fg, $fontlist, $ptsize, $angle, $x, $y, $string )

Alias for gdImageStringTTF.

=cut


sub StringTTF
{
    return gdImageStringTTF ( @_ );
} # End of StringTTF()...


=head2 gdImageStringTTF

$image->gdImageStringTTF( $brect, $fg, $fontlist, $ptsize, $angle, $x, $y, $string )

=cut


sub gdImageStringTTF
{
    my $self = shift;
    return _gdImageStringTTF ( $self->{IMG_PTR}, @_ );
} # End of gdImageStringTTF()...


=head2 StringFT

$image->StringFT( $brect, $fg, $fontlist, $ptsize, $angle, $x, $y, $string )

Alias for gdImageStringFT.

=cut


sub StringFT
{
    return gdImageStringFT ( @_ );
} # End of StringFT()...


=head2 gdImageStringFT

$image->gdImageStringFT( $brect, $fg, $fontlist, $ptsize, $angle, $x, $y, $string )

=cut


sub gdImageStringFT
{
    my $self = shift;
    return _gdImageStringFT ( $self->{IMG_PTR}, @_ );
} # End of gdImageStringFT()...



=head1 AUTHOR

Judd Taylor, Orbital Systems, Ltd.
judd dot t at orbitalsystems dot com

=cut





# Exit with OK status

1;

		   