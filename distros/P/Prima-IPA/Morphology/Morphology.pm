# $Id$
package Prima::IPA::Morphology;
use strict;
require Exporter;

use vars qw(
            @ISA
            @EXPORT
            @EXPORT_OK
            %EXPORT_TAGS

            $AUTOLOAD

            %transform_luts
           );
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(BWTransform
                dilate erode opening closing
                algebraic_difference gradient
                reconstruct watershed thinning);
%EXPORT_TAGS = (binary => [qw(BWTransform)]);


sub opening {
   my $in = shift;
   my $out = erode($in,@_);
   $out = dilate($out,@_);
   $out-> name( "Prima::IPA::Morphology::opening");
   return $out;
}

sub closing {
   my $in = shift;
   my $out = dilate($in,@_);
   $out = erode($out,@_);
   $out-> name( "Prima::IPA::Morphology::closing");
   return $out;
}

sub gradient {
   my $img = shift;
   my $out = dilate($img,@_);
   my $erode = erode($img,@_);
   return algebraic_difference($out,$erode,inPlace=>'Yes');
}

sub AUTOLOAD {
    my ($subname)=$AUTOLOAD;
    $subname=~s/^Prima::IPA::Morphology:://;
    if ($subname=~/^bw_/) {
        my ($bwmethodname)=($subname);
        $bwmethodname=~s/^bw_//;
        if (ref($transform_luts{$bwmethodname}) eq 'CODE') {
            my ($lut)=$transform_luts{$bwmethodname}->();
            eval("sub $subname { return BWTransform(\$_\[0\],lookup=>\'$lut\'); }");
            croak("Prima::IPA::Morphology::AUTOLOAD: $@") if $@;
            goto &$subname;
        }
        else {
            croak("Prima::IPA::Morphology: internal error - not a code reference in hash for $bwmethodname");
        }
    }
    else {
        croak("Prima::IPA::Morphology: unknown method $AUTOLOAD called");
    }
}

sub X0 { return ($_[0] & 0x001 ? 255 : 0); };
sub X1 { return ($_[0] & 0x002 ? 255 : 0); };
sub X2 { return ($_[0] & 0x004 ? 255 : 0); };
sub X3 { return ($_[0] & 0x008 ? 255 : 0); };
sub X4 { return ($_[0] & 0x010 ? 255 : 0); };
sub X5 { return ($_[0] & 0x020 ? 255 : 0); };
sub X6 { return ($_[0] & 0x040 ? 255 : 0); };
sub X7 { return ($_[0] & 0x080 ? 255 : 0); };
sub X8 { return ($_[0] & 0x100 ? 255 : 0); };

%transform_luts=(
                 dilate => sub {
                                my ($rstr)="";
                                my ($i);
                                for ($i=0; $i<512; $i++) {
                                    $rstr.=chr(X0($i) | X1($i) | X2($i) |
                                               X3($i) | X4($i) | X5($i) |
                                               X6($i) | X7($i) | X8($i));
                                }
                                return $rstr;
                           },
                 erode =>  sub {
                                my ($rstr)="";
                                my ($i);
                                for ($i=0; $i<512; $i++) {
                                    $rstr.=chr(X0($i) & X1($i) & X2($i) &
                                               X3($i) & X4($i) & X5($i) &
                                               X6($i) & X7($i) & X8($i));
                                }
                                return $rstr;
                           },
                 isolatedremove =>
                           sub {
                                my ($rstr)="";
                                my ($i);
                                for ($i=0; $i<512; $i++) {
                                    $rstr.=chr(X0($i) & (X1($i) | X2($i) | X3($i) | X4($i) | X5($i) | X6($i) | X7($i) | X8($i)));
                                }
                                return $rstr;
                           },
                 togray => sub {
                                my ($rstr)="";
                                my ($i);
                                for ($i=0; $i<512; $i++) {
                                    $rstr.=chr((X0($i)+X1($i)+X2($i)+X3($i)+X4($i)+X5($i)+X6($i)+X7($i)+X8($i))/9);
                                }
                                return $rstr;
                           },
                 invert => sub {
                    my ($rstr)="";
                    my ($i);
                    for ($i=0; $i<512; $i++) {
                        $rstr.=chr(255-X0($i));
                    }
                    return $rstr;
                 },
                 prune => sub {
                     my @ret = ((0, 255) x 256); # ident
                     $ret[$_] = 0 for map { my $x = 1; $x |= 1 << $_ for split ''; $x; }
                        # 0-connected (isolated)
                        0,
                        # 1-connected 
                        1,2,3,4,5,6,7,8,
                        # 2-joint-connected 
                        12,23,34,45,56,67,78,
                        # 3-joint connected 
                        234,456,678,812
                     ;
                     return join '', map { chr } @ret;
                },
                break_node => sub {
                     my @ret = ((0, 255) x 256); # ident
                     my @nodes = map { my $x = 1; $x |= 1 << $_ for split ''; $x; }
                        # 3-connected
                        135, 246, 357, 468, 571, 682, 713, 824,
                        146, 257, 368, 471, 582, 613, 724, 835,
                        # 4-connected
                        1357, 2468
                     ;
                     for ( 0..511) {
                        my $ix = $_;
                        for ( @nodes) {
                           next unless ($_ & $ix) == $_;
                           $ret[$ix] = 0;
                           last;
                        }
                     }
                     return join '', map { chr } @ret;
                },
                );

1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Morphology - morphological operators

=head1 DESCRIPTION

Quote from L<http://www.dai.ed.ac.uk/HIPR2/morops.htm>:

Morphological operators often take a binary image and a structuring element as input 
and combine them using a set operator (intersection, union, inclusion, complement). 
They process objects in the input image based on characteristics of its shape, which are 
encoded in the structuring element. 

Usually, the structuring element is sized 3x3 and has its origin at the center pixel. 
It is shifted over the image and at each pixel of the image its elements are compared with 
the set of the underlying pixels. If the two sets of elements match the condition defined 
by the set operator (e.g. if the set of pixels in the structuring element is a subset 
of the underlying image pixels), the pixel underneath the origin of the structuring 
element is set to a pre-defined value (0 or 1 for binary images). 
A morphological operator is therefore defined by its structuring element and the 
applied set operator. 

Morphological operators can also be applied to gray-level images, e.g. 
to reduce noise or to brighten the image. 

=over

=item BWTransform IMAGE [ lookup ]

Applies 512-byte C<lookup> LUT string ( look-up table ) to image and returns 
the convolution result ( hit-and-miss transform). Each byte of C<lookup> is a set 
of bits, each corresponding to the 3x3 kernel index:

   |4 3 2|
   |5 0 1|
   |6 7 8|

Thus, for example, the X-shape would be represented by offset 2**0 + 2**2 + 2**4 + 2**6 + 2**8 = 341 .
The byte value, corresponding to the offset in C<lookup> string is stored in the output
image.

C<Prima::IPA::Morphology> defines several basic LUT transforms, which can be invoked by the following
code:

    Prima::IPA::Morphological::bw_METHOD( $image);

or its alternative

    Prima::IPA::Morphology::BWTransform( $image, lookup => $Prima::IPA::Morphology::transform_luts{METHOD}->());

Where METHOD is one of the following string constants:

=over

=item dilate

Morphological dilation

=item erode

Morphological erosion

=item isolatedremove

Remove isolated pixels

=item togray

Convert binary image to grayscale by applying the mean filter

=item invert

Inversion operator

=item prune

Removes 1-connected end points

=item break_node

Removes node points that connect 3 or more lines

=back

Supported types: Byte

=item dilate IMAGE [ neighborhood = 8 ]

Performs morphological dilation operation on IMAGE and returns the result.
C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item erode IMAGE [ neighborhood = 8 ]

Performs morphological erosion operation on IMAGE and returns the result.
C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item opening IMAGE [ neighborhood = 8 ]

Performs morphological opening operation on IMAGE and returns the result.
C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item closing IMAGE [ neighborhood = 8 ]

Performs morphological closing operation on IMAGE and returns the result.
C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item gradient IMAGE [ neighborhood = 8 ]

Returns the result or the morphological gradient operator on IMAGE.
C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item algebraic_difference IMAGE1, IMAGE2 [ inPlace = 0 ]

Performs the algebraic difference between IMAGE1 and IMAGE2.
Although this is not a morphological operator, it is often used is
conjunction with ones. If the boolean flag C<inPlace> is set, 
IMAGE1 contains the result.

Supported types: Byte, Short, Long, Float, Double

=item watershed IMAGE [ neighborhood = 4 ]

Applies the watershed segmentation to IMAGE with given C<neighborhood>.

Supported types: Byte

=item reconstruct IMAGE1, IMAGE2 [ neighborhood = 8, inPlace = 0 ]

Performs morphological reconstruction of IMAGE1 under the mask IMAGE2. Images can be two 
intensity images or two binary images with the same size. The returned image, is an intensity 
or binary image, respectively. 

If boolean C<inPlace> flag is set, IMAGE2 contains the result.

C<neighborhood> determines whether the algorithm assumes 4- or 8- pixel connectivity.

Supported types: Byte, Short, Long, Float, Double

=item thinning IMAGE

Applies the skeletonization algorithm, returning image with binary object maximal
euclidian distance points set.

Supported types: Byte

=back

=cut
