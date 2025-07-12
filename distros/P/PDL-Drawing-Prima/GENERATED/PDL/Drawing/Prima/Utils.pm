#
# GENERATED WITH PDL::PP from utils.pd! Don't modify!
#
package PDL::Drawing::Prima::Utils;

our @EXPORT_OK = qw(color_to_rgb rgb_to_color hsv_to_rgb rgb_to_hsv minmaxforpair collate_min_max_wrt_many trim_collated_min trim_collated_max );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.18';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Drawing::Prima::Utils $VERSION;








#line 7 "utils.pd"

=head1 NAME

PDL::Drawing::Prima::Utils - A handful of useful utilities.

=head1 DESCRIPTION

These functions provide a number of utilities that do not depend on the Prima
toolkit but which are useful for Prima/PDL interaction. The first set of
functions assist in converting colors from one format to another. The second set
of functions are important for the auto-scaling calculations in
L<PDL::Graphics::Prima>. Strictly speaking, they should probably be defined
somewhere in that module, but they reside here at the moment.

=cut
#line 43 "Utils.pm"


=head1 FUNCTIONS

=cut






=head2 color_to_rgb

=for sig

 Signature: (int color(); int [o] rgb(n=3))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $rgb = color_to_rgb($color);
 color_to_rgb($color, $rgb);  # all arguments given
 $rgb = $color->color_to_rgb; # method call
 $color->color_to_rgb($rgb);

=pod

=for ref

Converts a Prima color value to RGB representation

If the input piddle has dimension (m, n, ...), the output piddle has
dimensions (3, m, n, ...). The first element represents the red value, the
second the green value, and the third the blue value. The resulting piddle is
suitable for use in C<rgb_to_color> or C<rgb_to_hsv>.

The code for this routine is based on C<value2rgb> from L<Prima::colorDialog>.

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<color_to_rgb> encounters a bad value in the input, the output piddle will
be marked as bad and the associated rgb values will all be marked with the bad
value.

=cut




*color_to_rgb = \&PDL::color_to_rgb;






=head2 rgb_to_color

=for sig

 Signature: (int rgb(n=3); int [o] color())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $color = rgb_to_color($rgb);
 rgb_to_color($rgb, $color);  # all arguments given
 $color = $rgb->rgb_to_color; # method call
 $rgb->rgb_to_color($color);

=pod

=for ref

Converts an RGB color to a Prima color value

Red, green, and blue values must fall between 0 and 255. Any values outside
those boundaries will be truncated to the nearest boundary before computing the
color.

The RGB values must be in the first dimension. In other words, the size of the
first dimension must be three, so if the input piddle has dimensions (3, m, n,
...), the output piddle will have dimension (m, n, ...). The resulting piddle is
suitable for use when specifying colors to drawing primitives.

The code for this routine is based on C<rgb2value> from L<Prima::colorDialog>.

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_color> encounters a bad value in any of the red, green, or blue
values of the input, the output piddle will be marked as bad and the associated
color values will all be marked as bad.

=cut




*rgb_to_color = \&PDL::rgb_to_color;






=head2 hsv_to_rgb

=for sig

 Signature: (float+ hsv(n=3); int [o]rgb(m=3))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $rgb = hsv_to_rgb($hsv);
 hsv_to_rgb($hsv, $rgb);  # all arguments given
 $rgb = $hsv->hsv_to_rgb; # method call
 $hsv->hsv_to_rgb($rgb);

=pod

=for ref

Converts an HSV color triple to an RGB color triple

HSV stands for hue-saturation-value and is nicely represented by a cirle in a
color palette. In this representation, the numbers representing saturation and
value must be between 0 and 1; anything less than zero or greater than 1 will be
truncated to the closest limit. The hue must be a value between 0 and 360, and
again it will be truncated to the corresponding limit if that is not the case.
For more information about HSV, see L<http://en.wikipedia.org/wiki/HSL_and_HSV>.

Note that Prima's C<hsv2rgb> function, upon which this was based, had a special
notation for a hue of -1, which always corresponded to a saturation of 0. Since
a saturation of 0 means 'use greyscale', this function does not make any special
use of that notation.

The first dimension of the piddles holding the hsv and rgb values must be size
3, i.e. the dimensions must look like (3, m, n, ...). The resulting piddle is
suitable for input into L</rgb_to_color> as well as manual manipulation.

The code for this routine is based on C<hsv2rgb> from L<Prima::colorDialog>.

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<hsv_to_rgb> encounters a bad value in any of the hue, saturation, or value
quantities, the output piddle will be marked as bad and the associated rgb
color values will all be marked as bad.

=cut




*hsv_to_rgb = \&PDL::hsv_to_rgb;






=head2 rgb_to_hsv

=for sig

 Signature: (int rgb(n=3); float+ [o]hsv(m=3))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $hsv = rgb_to_hsv($rgb);
 rgb_to_hsv($rgb, $hsv);  # all arguments given
 $hsv = $rgb->rgb_to_hsv; # method call
 $rgb->rgb_to_hsv($hsv);

=pod

=for ref

Converts an RGB color triple to an HSV color triple

HSV stands for hue-saturation-value and is nicely represented by a cirle in a
color palette. In this representation, the numbers representing saturation and
value will run between 0 and 1. The hue will be a value between 0 and 360.
For more information about HSV, see L<http://en.wikipedia.org/wiki/HSL_and_HSV>.

Note that Prima's C<rgb2hsv> function, upon which this was based, returned a
special value if r == g == b. In that case, it returned a hue of -1 and a
saturation of zero. In the rgb color is a greyscale and the value is based
simply on that. This function does not make use of that special hue value; it
simply returns a hue value of 0.

The first dimension of the piddles holding the hsv and rgb values must be size
3, i.e. the dimensions must look like (3, m, n, ...). The resulting piddle is
suitable for manual manipulation and input into L</hsv_to_rgb>.

The code for this routine is based on C<rgb2hsv> from L<Prima::colorDialog>.

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_hsv> encounters a bad value in any of the red, green, or blue values
the output piddle will be marked as bad and the associated hsv values will all
be marked as bad.

=cut




*rgb_to_hsv = \&PDL::rgb_to_hsv;






=head2 minmaxforpair

=for sig

 Signature: (x(n); y(n); [o] min_x(); [o] min_y(); [o] max_x(); [o] max_y())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 ($min_x, $min_y, $max_x, $max_y) = minmaxforpair($x, $y);
 minmaxforpair($x, $y, $min_x, $min_y, $max_x, $max_y);    # all arguments given
 ($min_x, $min_y, $max_x, $max_y) = $x->minmaxforpair($y); # method call
 $x->minmaxforpair($y, $min_x, $min_y, $max_x, $max_y);

=pod

=for ref

Returns the min/max values for the pairs of coordinates x and y.

This function is only really useful in one very specific context: when the
number of dimensions for x and y do not agree, and when you have bad data in
x, y, or both.

Suppose that you know that x and y are good. Then you could get the min/max
data using the C<minmax> function:

 my ($xmin, $xmax) = $x->minmax;
 my ($ymin, $ymax) = $y->minmax;

On the other hand, if you have bad data but you know that the dimensions of x
and y match, you could modify the above like so:

 my ($xmin, $xmax) = $x->where($x->isgood & $y->isgood)->minmax;
 my ($ymin, $ymax) = $y->where($x->isgood & $y->isgood)->minmax;

However, what if you have only one-dimensional x-data but two-dimensional
y-data? For example, you want to plot mutliple y datasets against the same
x-coordinates. In that case, if some of the x-data is bad, you could probably
hack something, but if some of the y-data is bad you you will have a hard time
picking out the good pairs, and getting the min/max from them. That is the
purpose of this function.

	

=pod

Broadcasts over its inputs.

=for bad

=pod

Output is set bad if no pair of x/y data is good.

	

=cut




*minmaxforpair = \&PDL::minmaxforpair;






=head2 collate_min_max_wrt_many

=for sig

 Signature: (min_check(Q); int min_index(Q); max_check(Q); int max_index(Q); extra0(Q); extra1(Q); extra2(Q); extra3(Q); extra4(Q); extra5(Q); extra6(Q); extra7(Q); extra8(Q); extra9(Q); extra10(Q); extra11(Q); extra12(Q); extra13(Q); extra14(Q); extra15(Q); extra16(Q); extra17(Q); extra18(Q); extra19(Q); [o] min(N); [o] max(N); int N_extras)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 ($min, $max) = collate_min_max_wrt_many($min_check, $min_index, $max_check, $max_index, $extra0, $extra1, $extra2, $extra3, $extra4, $extra5, $extra6, $extra7, $extra8, $extra9, $extra10, $extra11, $extra12, $extra13, $extra14, $extra15, $extra16, $extra17, $extra18, $extra19, $N_extras);
 collate_min_max_wrt_many($min_check, $min_index, $max_check, $max_index, $extra0, $extra1, $extra2, $extra3, $extra4, $extra5, $extra6, $extra7, $extra8, $extra9, $extra10, $extra11, $extra12, $extra13, $extra14, $extra15, $extra16, $extra17, $extra18, $extra19, $min, $max, $N_extras);    # all arguments given
 ($min, $max) = $min_check->collate_min_max_wrt_many($min_index, $max_check, $max_index, $extra0, $extra1, $extra2, $extra3, $extra4, $extra5, $extra6, $extra7, $extra8, $extra9, $extra10, $extra11, $extra12, $extra13, $extra14, $extra15, $extra16, $extra17, $extra18, $extra19, $N_extras); # method call
 $min_check->collate_min_max_wrt_many($min_index, $max_check, $max_index, $extra0, $extra1, $extra2, $extra3, $extra4, $extra5, $extra6, $extra7, $extra8, $extra9, $extra10, $extra11, $extra12, $extra13, $extra14, $extra15, $extra16, $extra17, $extra18, $extra19, $min, $max, $N_extras);

=for ref

=pod

Broadcasts over its inputs.

=for bad

C<collate_min_max_wrt_many> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





=head2 collate_min_max_wrt_many

=for sig

  Signature: ($min(N_pixels), $max(N_pixels))
               = collate_min_max_wrt_many(
                   $min_to_collate(M); $min_index(M);
                   $max_to_collate(M); $max_index(M);
                   N_pixels; $p1(M); $p2(M); ...);

=for ref

Collates the min/max two piddles according to their supplied indices.

This function pretty much only makes sense in the context of
PDL::Graphics::Prima and it's auto-scaling calculations. Here's how it
works.

Suppose you're drawing a collection of colored blobs. Your blobs have
various radii and you want to know the min and the max x-positions, collated
for each radius. In other words, for all the blobs with radius 1, give me
the min and the max; for all the blobs with radius 2, give me the min and
the max; etc. However, you are not going to draw the blobs that have a 
badvalue for a the y position or the color---badvalues for any of these mean
"skip me". You only want to know the minima and maxima for the blobs that
you intend to draw. Also, let's assume that the widget onto which you intend
to draw is 500 pixels wide.

For that situation, you would call collate_min_max_wrt_many like so:

 my ($min, $max) = PDL::collate_min_max_wrt_many($x, $xRadii, $x, $xRadii
                                  , 500, $y, $yRadii, $colors);

The arguments are interpreted as follows. The first two piddles are the
values and the indices of the data from which we wish to draw the minima.
Here we want to find the smallest value of x, collated according to the
specified pixel radii. The next two piddles are the values and indices of
the data from which we wish to draw the maxima. The fifth argument, a scalar
number, indicates the maximum collation bin.

The remainder of the arguments are values against which we want to check
for bad values. For example, suppose the first (x, y) pair is (2, inf). This
point will not be drawn, because infinity cannot be drawn, so I will not
want to collate that x-value of 2, regardless of the xRadius with which it
corresponds. So, each value of x is included in the min/max collation only
if all the other piddles have good values at the same index.

This function threads over as many as 20 extra piddles, checking each
of them to see if they have bad values, inf, or nan. The limit to 20 piddles
is a hard but arbitrary limit. It could be increased if the need arose, but
the function would need to be recompiled.

=for bad

This function is explicitly meant to handle bad values. The output piddles
will have bad values for any index that was not represented in the
calculation. If any of the supplied piddles have bad values, the
corresponding position will not be analyzed.

=cut

use Carp 'croak';

sub PDL::collate_min_max_wrt_many {
	my ($min_to_check, $min_index, $max_to_check, $max_index, $N_pixels
		, @extra_piddles) = @_;
	
	# Ensure all the things that are supposed to be piddles are indeed
	# piddles:
	foreach ($min_to_check, $min_index, $max_to_check, $max_index, @extra_piddles) {
		$_ = PDL::Core::topdl($_);
	}
	
	# Determine the number of piddles over which to thread:
	my $N_extras = scalar(@extra_piddles);
	
	croak("Currently, collate_min_max_for_many only allows up to 20 extra piddles")
		if $N_extras > 20;
	
	# Determine the dimensions of the min/max piddles, starting with the
	# min/max piddles and their indices, and then moving to the extras:
	my @dims = $min_to_check->dims;
	my %to_consider = (min_index => $min_index
				, max_to_check => $max_to_check, max_index => $max_index);
	while (my ($name, $piddle) = each(%to_consider)) {
		for(my $idx = 0; $idx < $piddle->ndims; $idx++) {
			my $dim = $piddle->dim($idx);
			# Some sanity checks
			if (not exists $dims[$idx] or $dims[$idx] == 1) {
				$dims[$idx] = $dim;
			}
			elsif($dim != 1 and $dims[$idx] != $dim) {
				croak("Index mismatch in collate_min_max_wrt_many for piddle $name:\n"
						. "   Expected dim($idx) = $dims[$idx] but got $dim")
			}
		}
	}
	
	# Next, check the extra dimensions.
	for (my $piddle_count = 0; $piddle_count < @extra_piddles; $piddle_count++) {
		my $piddle = $extra_piddles[$piddle_count];
		for(my $idx = 0; $idx < $piddle->ndims; $idx++) {
			my $dim = $piddle->dim($idx);
			# Some sanity checks
			if (not exists $dims[$idx] or $dims[$idx] == 1) {
				$dims[$idx] = $dim;
			}
			elsif($dim != 1 and $dims[$idx] != $dim) {
				croak("Index mismatch in collate_min_max_wrt_many for extra piddle $piddle_count:\n"
						. "   Expected dim($idx) = $dims[$idx] but got $dim");
			}
		}
	}
	# We'll be threading over the first dimension, so get rid of that:
	shift @dims;
	
	# Build the min and max piddles:
	my $min = zeroes($N_pixels+1, @dims)->setvaltobad(0);
	my $max = $min->copy;
	$min_to_check->badflag(1);
	
	# Pad out the list of extra piddles so the threading engine has piddles
	# to handle:
	while(@extra_piddles < 20) {
		push @extra_piddles, zeroes(1);
	}
	
	# Call the underlying PP function
	PDL::_collate_min_max_wrt_many_int($min_to_check, $min_index,
		$max_to_check, $max_index, @extra_piddles, $min, $max, $N_extras);
	
	# Return the results
	return ($min, $max);
}




*collate_min_max_wrt_many = \&PDL::collate_min_max_wrt_many;






=head2 trim_collated_min

=for sig

 Signature: (minima(m, a=3); int [o] min_mask(m))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $min_mask = trim_collated_min($minima);
 trim_collated_min($minima, $min_mask);  # all arguments given
 $min_mask = $minima->trim_collated_min; # method call
 $minima->trim_collated_min($min_mask);

=pod

=for ref

Returns a mask to trim a collated list of minima so that the resulting
(masked off) entries are in strictly decreasing order with increasing index.

working here - this needs documentation

	

=pod

Broadcasts over its inputs.

=for bad

C<trim_collated_min> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*trim_collated_min = \&PDL::trim_collated_min;






=head2 trim_collated_max

=for sig

 Signature: (maxima(n, a=3); int [o] max_mask(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $max_mask = trim_collated_max($maxima);
 trim_collated_max($maxima, $max_mask);  # all arguments given
 $max_mask = $maxima->trim_collated_max; # method call
 $maxima->trim_collated_max($max_mask);

=pod

=for ref

Returns a mask to trim a collated list so that the resulting (masked off)
entries are in strictly decreasing extremeness with increasing index.

working here - this needs documentation

	

=pod

Broadcasts over its inputs.

=for bad

C<trim_collated_max> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*trim_collated_max = \&PDL::trim_collated_max;







# Exit with OK status

1;
