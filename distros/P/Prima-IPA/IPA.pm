# $Id$
package Prima::IPA;
use strict;
use Prima;
require Exporter;
require DynaLoader;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $__import);
@ISA = qw(Exporter DynaLoader);

sub dl_load_flags { 0x01 };

$VERSION = '1.09';
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();

bootstrap Prima::IPA $VERSION;

use constant combineMaxAbs       => 1;
use constant combineSumAbs       => 2;
use constant combineSum          => 3;
use constant combineSqrt         => 4;
use constant combineSignedMaxAbs => 5;
use constant combineMultiply     => 6;

use constant conversionTruncAbs  => 1;
use constant conversionTrunc     => 2;
use constant conversionScale     => 3;
use constant conversionScaleAbs  => 4;

sub import
{
   my $self = shift;
   my @modules = ( 1 == @_ && lc($_[0]) eq 'all') ? 
      qw(Point Local Global Geometry Morphology Misc Region) 
      : @_;
   for ( @modules) {
       eval "use Prima::IPA::$_ ();";
       die $@ if $@;
       Exporter::export_to_level( "Prima::IPA::$_", 1, undef, '/./') 
          if UNIVERSAL::isa("Prima::IPA::$_", 'Exporter');
   }
}

1;

__END__

=pod

=head1 NAME

Prima::IPA - Image Processing Algorithms

=head1 DESCRIPTION

IPA stands for Image Processing Algorithms and represents the library of image
processing operators and functions.  IPA is based on the Prima toolkit (
http://www.prima.eu.org ), which in turn is a perl-based graphic library. IPA
is designed for solving image analysis and object recognition tasks in perl.

Note: This module overrides old C<IPA> module.

=head1 USAGE

IPA works mostly with grayscale images, which can be loaded or created by means
of Prima toolkit. See L<Prima::Image> for the information about C<Prima::Image>
class functionality.  IPA methods are grouped in several modules, that contain
the specific functions. The functions usually accept one or more images and
optional parameter hash. Each function has its own set of parameters. If error
occurs, the functions call C<die>, so it is advisable to use C<eval> blocks
around the calls.

The modules namespaces can be used directly, e.g. C<use Prima::IPA::Local qw(/./)>,
C<use Prima::IPA::Point qw(/./)> etc, with each module defining its own set of
exportable names. In case when all names are to be exported, it is possible to
use C<IPA.pm> exporter by using C<use Prima::IPA qw(Local Point)> syntax, which is
equivalent to two separate C<'use'> calls above. Moreover, if all modules are
to be loaded and namespace exported, special syntax C<use Prima::IPA 'all'> is
available.

For example, a code that produces a binary thresholded image out of a 8-bit 
grayscale image:

   use Prima;
   use Prima::IPA qw(Point);
   my $i = Prima::Image-> load('8-bit-grayscale.gif');
   die "Cannot load:$@\n" if $@;
   my $binary = threshold( $i, minvalue => 128);

The abbreviations for pixel types are used, derived from
the C<im::XXX> image type constants, as follows:

   im::Byte     - 8-bit unsigned integer
   im::Short    - 16-bit signed integer
   im::Long     - 32-bit signed integer
   im::Float    - float
   im::Double   - double
   im::Complex  - complex float
   im::DComplex - complex double

Each function returns the newly created image object with the result of the operation,
unless stated otherwise in L<API>.

=head1 MODULES

L<Prima::IPA::Geometry> - mapping pixels from one location to another

L<Prima::IPA::Point> - single pixel transformations and image arithmetic

L<Prima::IPA::Local> - methods that produce images where every pixel is a function of pixels in the neighborhood

L<Prima::IPA::Global> - methods that produce images where every pixel is a function of all pixels in the source image

L<Prima::IPA::Region> - region data structures

L<Prima::IPA::Morphology> - morphological operators

L<Prima::IPA::Misc> - miscellaneous uncategorized routines

=head1 REFERENCES

=over

=item *

M.D. Levine. Vision in Man and Machine.  McGraw-Hill, 1985. 

=item *

R. Deriche. Using Canny's criteria to derive a recursively implemented optimal edge detector. 
International Journal on Computer Vision, pages 167-187, 1987. 

=item *

R. Boyle and R. Thomas Computer Vision. A First Course, 
Blackwell Scientific Publications, 1988, pp 32 - 34. 

=item *

Image Processing Learning Resources.
L<http://www.dai.ed.ac.uk/HIPR2/hipr_top.htm>

=item *

William K. Pratt.  Digital Image Processing.     
John Wiley, New York, 2nd edition, 1991

=item *

John C. Russ. The Image Processing Handbook.
CRC Press Inc., 2nd Edition, 1995

=item *

L. Vincent & P. Soille.  Watersheds in digital 
spaces:  an efficient algorithm based on immersion
simulations.  IEEE Trans. Patt. Anal. and Mach.
Intell., vol. 13, no. 6, pp. 583-598, 1991

=item *

L. Vincent. Morphological Grayscale Reconstruction in Image Analysis: 
Applications and Efficient Algorithms. 
IEEE Transactions on Image Processing, vol. 2, no. 2, April 1993, pp. 176-201.

=item * 

J. Canny, "A computational approach to edge detection, " IEEE Transactions on
Pattern Analysis and Machine Intelligence, vol. 8, pp. 679--698, 1986. 18 Weber
and Malik

=item * 

Tony Lindeberg .  "Edge Detection and Ridge Detection with Automatic Scale Selection ".
International Journal of Computer Vision, vol. 30, n. 2, pp. 77--116, 1996.  

=back

=head1 SEE ALSO

L<Prima>, L<iterm>,


=head2 COPYRIGHT AND LICENSE

(c) 1997-2002 The Protein Laboratory, University of Copenhagen
(c) 2003-2007 Dmitry Karasik

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Anton Berezin E<lt>tobez@tobez.orgE<gt>,
Vadim Belman E<lt>voland@lflat.orgE<gt>,
Dmitry Karasik E<lt>dmitry@karasik.eu.orgE<gt>

=cut
