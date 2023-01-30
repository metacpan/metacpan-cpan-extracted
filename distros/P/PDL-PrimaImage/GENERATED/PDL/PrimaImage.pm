#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::PrimaImage;

our @EXPORT_OK = qw(image2piddle );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::PrimaImage ;






#line 3 "primaimage.pd"


BEGIN { $VERSION = '1.03'; }

*image2piddle = \&PDL::image2piddle;

sub image
{
	my ( $piddle, %options) = @_;
	die "image: invalid parameter\n" unless defined $piddle;
	my $i = Prima::Image-> create();
	my ( $t0, $t2) = ( $piddle->getdim(0), $piddle->getdim(2));
	my $mpixel = 0;
	$mpixel = 1 if
		( $t2 == 1 && $t0 < 3 && ( $options{complex} || $options{rgb})) ||
		$t2 > 1;
	PDL::PrimaImage::image2piddle( $piddle, $i, 0, $mpixel);
	return $i;
}

no warnings 'redefine';
sub piddle
{
	my ( $image, %options) = @_;
	die "piddle: invalid parameter\n" unless defined $image;
	my $piddle;
	my ( $x, $y) = $image-> size;
	my $itype = $image-> type;
	my $z = 1;
	my $ptype;
	if ( $itype & (im::ComplexNumber|im::TrigComplexNumber)) {
		$ptype = ( $itype == im::Complex || $itype == im::TrigComplex) ? float : double;
		$z = 2;
	} elsif ( $itype & im::RealNumber) {
		$ptype = ( $itype == im::Float) ? float : double;
	} elsif ( $itype & im::GrayScale) {
		if ( $itype == im::Long) {
			$ptype = long;
		} elsif ( $itype == im::Short) {
			$ptype = short;
		} elsif ( $itype == im::Byte) {
			$ptype = byte;
		} else {
			$image = $image-> dup;
			$image-> type( im::Byte);
			$ptype = byte;
		}
	} elsif ( $itype == im::RGB) {
		$ptype = byte;
		$z = 3;
	} elsif ( $itype == 8) {
		$ptype = byte;
	} else {
		if ( $options{raw}) {
			$x = int(( $x * ( $itype & im::BPP) + 31) / 32) * 4;
		} else {
			$image = $image-> dup;
			$image-> type( im::bpp8);
		}
		$ptype = byte;
	}

	$piddle = ( $z > 1) ? zeroes( $ptype, $z, $x, $y) : zeroes( $ptype, $x, $y);
	PDL::PrimaImage::image2piddle( $piddle, $image, 1, ( $z > 1) ? 1 : 0);
	return $piddle;
}

=pod

=head1 NAME

PDL::PrimaImage - interface between PDL scalars and Prima images 

=head1 DESCRIPTION

Converts a 2D or 3D PDL scalar into Prima image and vice versa.

=head1 SYNOPSIS

  use PDL;
  use Prima;
  use PDL::PrimaImage;

  my $x = byte([ 10, 111, 2, 3], [4, 115, 6, 7]);
  my $i = PDL::PrimaImage::image( $x);
  $i-> type( im::RGB);
  $x = PDL::PrimaImage::piddle( $i);


=head2 image PDL, %OPTIONS

Converts a 2D or 3D piddle into a Prima image. The resulting image pixel format
depends on the piddle type and dimension.  The 2D array is converted into one
of C<im::Byte>, C<im::Short>, C<im::Long>, C<im::Float>, or C<im::Double> pixel
types.

For the 3D arrays each pixel is expected to be an array of values.  C<image>
accepts arrays with 2 and 3 values.  For an array with 2 values, the resulting
pixel format is complex ( with C<im::ComplexNumber> bit set), where each pixel
contains 2 values, either C<float> or C<double>, correspondingly to
<im::Complex> and C<im::DComplex> pixel formats.

For an array with 3 values, the C<im::RGB> pixel format is assumed. In this
format, each image pixel is represented as a single combined RGB value.

To distinguish between degenerate cases, like f ex ([1,2,3],[4,5,6]), where it
is impossible to guess whether the piddle is a 3x2 gray pixel image or a 1x2
RGB image, C<%OPTIONS> hash can be used. When either C<rgb> or C<complex>
boolean value is set, C<image> assumes the piddle is a 3D array.  If neither
option is set, C<image> favors 2D array semantics.

NB: These hints are neither useful nor are checked when piddle format is
explicit, and should only be used for hinting an ambiguous data representation.

=head2 piddle IMAGE, %OPTIONS

Converts Prima image into a piddle. Depending on image pixel type,
the piddle type and dimension is selected. The following table depicts
how different image pixel formats affect the piddle type:


	Pixel format     PDL type  PDL dimension
	----------------------------------------
	im::bpp1          byte         2
	im::bpp4          byte         2
	im::bpp8          byte         2
	im::Byte          byte         2
	im::Short         short        2
	im::Long          long         2
	im::Float         float        2
	im::Double        double       2
	im::RGB           byte         3
	im::Complex       float        3
	im::DComplex      double       3
	im::TrigComplex   float        3
	im::TrigDComplex  double       3

Images in the pixel formats C<im::bpp1> and C<im::bpp4> are converted to
C<im::bpp8> before conversion to piddle, so if raw, non-converted data stream
is needed, in correspondingly 8- and 2- pixels perl byte format, C<raw> boolean
option must be specified in C<%OPTIONS>. In this case, the resulting piddle
width is aligned to a 4-byte boundary.

=head1 Considerations

Prima image coordinate origin is located in lower left corner.  That means,
that an image created from a 2x2 piddle ([0,0],[0,1]) will contain pixel with
value 1 in the upper right corner.

See L<Prima::Image> for more.

=head1 Troubleshooting

=over

=item Undefinedned symbol "gimme_the_vmt"

The symbol is contained in Prima toolkit. Include 'use Prima;' in your code. If
the error persists, it is probably Prima error; try to re-install Prima. If the
problem continues, try to change manually value in 'sub dl_load_flags { 0x00 }'
string to 0x01 in Prima.pm - this flag is used to control namespace export (
see L<Dynaloader> for more ).

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 SEE ALSO

PDL-PrimaImage page, http://www.prima.eu.org/PDL-PrimaImage/

The Prima toolkit, http://www.prima.eu.org/

L<PDL>, L<Prima>, L<Prima::Image>.

=cut
#line 204 "PrimaImage.pm"






=head1 FUNCTIONS

=cut




#line 949 "C:/usr/local/perl/sb64.532.1/perl/site/lib/PDL/PP.pm"



=head2 image2piddle

=for sig

  Signature: (data(z,w,h); SV * imagesv; int image2piddle; int mpixel)


=for ref

info not available


=for bad

image2piddle does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 241 "PrimaImage.pm"



#line 951 "C:/usr/local/perl/sb64.532.1/perl/site/lib/PDL/PP.pm"

*image2piddle = \&PDL::image2piddle;
#line 248 "PrimaImage.pm"





#line 185 "primaimage.pd"


=head1 TROUBLESHOOTING

=over

=item Undefinedned symbol "gimme_the_vmt"

The symbol is contained in Prima toolkit. Include 'use Prima;' 
in your code. If the error persists, it is probably Prima
error; try to re-install Prima. If the problem continues,
try to change manually value in 'sub dl_load_flags { 0x00 }'
string to 0x01 in Prima.pm - this flag is used to control
namespace export ( see L<Dynaloader> for more ).

=item 

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 SEE ALSO

PDL-PrimaImage page, http://www.prima.eu.org/PDL-PrimaImage/

The Prima toolkit, http://www.prima.eu.org/

L<PDL>, L<Prima>, L<Prima::Image>.

=cut
#line 287 "PrimaImage.pm"




# Exit with OK status

1;
