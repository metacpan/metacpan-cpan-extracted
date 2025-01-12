use v5.36;
use utf8;

package PeGS::PDF;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.103';

=encoding utf8

=head1 NAME

PeGS::PDF - Draw simple Perl Graphical Structures

=head1 SYNOPSIS

	use PeGS::PDF;

	my $pdf = PeGS::PDF->new(
		{
		file => "array.pdf",
		'x'  => 1.50 * 72,
		'y'  => 2.25 * 72,
		}
		);
	die "Could not create object!" unless ref $pdf;

	$pdf->make_array( '@cats', [ qw(Buster Mimi Ginger Ella) ], 10, 120 );

	$pdf->close;


=head1 DESCRIPTION

=over 4

=cut

use base qw(PDF::EasyPDF);

use List::Util qw(max);

=item padding_factor

=cut

sub padding_factor   { 0.7 }
sub font_height      { 10 }
sub font_width       { 6 }
sub font_size        { 10 }
sub connector_height { 10 }
sub black_bar_height { 5 }
sub stroke_width     { 0.5 }
sub pointy_width     { ( $_[0]->font_height + 2 * $_[0]->y_padding ) / 2 * sqrt(2) }
sub box_height       { $_[0]->font_height + 2 * $_[0]->y_padding }

sub y_padding { $_[0]->padding_factor * $_[0]->font_height }
sub x_padding { $_[0]->padding_factor * $_[0]->font_width  }

sub make_reference {
	my( $pdf, $name, $value, $bottom_left_x, $bottom_left_y ) = @_;

	my $scalar_width = $pdf->font_width * length $name;

	$pdf->make_pointy_box(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width + 2 * $pdf->x_padding,
		$pdf->box_height,
		$name
		);

	$pdf->lines(
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y,
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y - 10,
		);

	$pdf->make_text_box(
		$bottom_left_x,
		$bottom_left_y - 10 - $pdf->font_height - 2 * $pdf->y_padding,
		$scalar_width  + 2 * $pdf->x_padding,
		$pdf->box_height,
		''
		);

	my $arrow_start = XYPoint->new(
		$bottom_left_x + ( $scalar_width + 2 * $pdf->x_padding ) / 2,
		$bottom_left_y + $pdf->box_height / 2 - $pdf->connector_height - $pdf->box_height - 2*$pdf->stroke_width,
		);

	my $target = $pdf->{refs}{"$value"} //= XYPoint->new(
	    $arrow_start->clone->add_x( 50 )->x,
		$arrow_start->y, # ++ ,,
		);

	$pdf->make_reference_arrow(
		$arrow_start,
		$target,
		);

	$pdf->make_reference_icon($arrow_start);

	my $x = $pdf->arrow_length( $scalar_width ) + $bottom_left_x + ( $scalar_width + 2 * $pdf->x_padding ) / 2;

	if(    ref $value eq ref \ '' ) {

		}
	elsif( ref $value eq ref [] ) {
		$pdf->make_list(
			$value,
			$target->x,
			$target->y - $pdf->black_bar_height / 2, # -
			);
		}
	elsif( ref $value eq ref {} ) {
		$pdf->make_anonymous_hash(
			$value,
			$target->x,
			$target->y - $pdf->black_bar_height / 2, # -
			);
		}

	}

sub make_circle {
	my( $pdf,
		$xc, # x at the center of the circle
		$yc, # y at the center of the circle
		$r   # radius
		) = @_;

	$pdf->lines( $xc, $yc + 30, $xc, $yc - 30 );
	$pdf->lines( $xc - 30, $yc, $xc + 30, $yc );

	my $points = 5;
	my $Pi = 3.1415926;

	my $arc = 2 * $Pi / $points;

	my $darc = $arc * 360 / ( 2 * $Pi );

=pod

	my @points = map
		[ $xc + $r * cos( $arc * $_ / 2 ), $yc + $r * sin( $arc * $_ / 2 ) ],
		0 .. $points - 1;

=cut

	my @points = (
		[ $r * cos(       $arc / 2 ),   $r * sin(       $arc / 2 ) ],
		[ $r * cos( -     $arc / 2 ),   $r * sin( -     $arc / 2 ) ],
		);

	$pdf->{stream} .= "@{$points[0]} m\n";

	foreach my $i ( 0 .. $points - 1 ) {
		my( @xp, @yp );

		( $xp[0], $yp[0], $xp[3], $yp[3] ) = ( @{ $points[0] }, @{ $points[1] } );

		( $xp[1], $yp[1] ) = ( (4 * $r - $xp[0])/3, (1-$xp[0])*(3-$xp[0])/(3*$yp[0]) );

		( $xp[2], $yp[2] ) = ( $xp[1], -$yp[1] );

		# rotate and translate
		my @x = map { $_ + $xc } map {   $xp[$_] * cos( $arc * $i ) + $yp[$_] * sin( $arc * $i ) } 0 .. $#xp;
		my @y = map { $_ + $yc } map { - $xp[$_] * sin( $arc * $i ) + $yp[$_] * cos( $arc * $i ) } 0 .. $#yp;

		$pdf->{stream} .= "$x[0] $y[0] m\n$x[1] $y[1] $x[2] $y[2] $x[3] $y[3] c\nf\n";

		#$pdf->lines( $x0, $y0, $x1, $y1 );
		#$pdf->lines( $x1, $y1, $x1, $y1 + 10 );
		#$pdf->lines( $x3, $y3, $x2, $y2 );
		#$pdf->lines( $x2, $y2, $x2, $y2 - 10 );
		}

	}

=pod

$c .= sprintf(' %.2f %.2f %.2f %.2f %.2f %.2f c',
                  $x + $b, $y,
                  $x + $r, $y - $r + $b,
                  $x + $r, $y - $r);
    /* Set x/y to the final point. */
    $x = $x + $r;
    $y = $y - $r;
    /* Third circle quarter. */
    $c .= sprintf(' %.2f %.2f %.2f %.2f %.2f %.2f c',
                  $x, $y - $b,
                  $x - $r + $b, $y - $r,
                  $x - $r, $y - $r);
    /* Set x/y to the final point. */
    $x = $x - $r;
    $y = $y - $r;
    /* Fourth circle quarter. */
    $c .= sprintf(' %.2f %.2f %.2f %.2f %.2f %.2f c %s',
                  $x - $b, $y,
                  $x - $r, $y + $r - $b,
                  $x - $r, $y + $r,
                  $op);
=cut

sub make_magic_circle {
	my( $pdf,
		$center,
		$r   # radius
		) = @_;

	my( $xc, $yc ) = $center->xy;

	my $magic = $r * 0.552;
	my( $x0p, $y0p ) = ( $xc - $r, $yc );
	$pdf->{stream} .= "$x0p $y0p m\n";

	{
	( $x0p, $y0p ) = ( $xc - $r, $yc );
	my( $x1, $y1 ) = ( $x0p,               $y0p + $magic );
	my( $x2, $y2 ) = ( $x0p + $r - $magic, $y0p + $r     );
	my( $x3, $y3 ) = ( $x0p + $r,          $y0p + $r     );
	$pdf->{stream} .= "$x1 $y1 $x2 $y2 $x3 $y3 c\n";
	}

	{
	( $x0p, $y0p ) = ( $xc, $yc + $r );
	my( $x1, $y1 ) = ( $x0p + $magic, $y0p               );
	my( $x2, $y2 ) = ( $x0p + $r,     $y0p - $r + $magic );
	my( $x3, $y3 ) = ( $x0p + $r,     $y0p - $r          );
	$pdf->{stream} .= "$x1 $y1 $x2 $y2 $x3 $y3 c\n";
	}

	{
	( $x0p, $y0p ) = ( $xc + $r, $yc );
	my( $x1, $y1 ) = ( $x0p,               $y0p - $magic );
	my( $x2, $y2 ) = ( $x0p - $r + $magic, $y0p - $r     );
	my( $x3, $y3 ) = ( $x0p - $r,          $y0p - $r     );
	$pdf->{stream} .= "$x1 $y1 $x2 $y2 $x3 $y3 c\n";
	}

	{
	( $x0p, $y0p ) = ( $xc, $yc - $r );
	my( $x1, $y1 ) = ( $x0p - $magic,               $y0p );
	my( $x2, $y2 ) = ( $x0p - $r, $y0p + $r - $magic    );
	my( $x3, $y3 ) = ( $x0p - $r,          $y0p + $r     );
	$pdf->{stream} .= "$x1 $y1 $x2 $y2 $x3 $y3 c\n";
	}

	$pdf->{stream} .= "f\n";
	}

sub make_regular_polygon {
	my( $pdf,
		$xc, # x at the center of the circle
		$yc, # y at the center of the circle
		$points,
		$r   # radius,
		) = @_;

	my $arc = 2 * 3.1415926 / $points;

	my @points = map
		[ $xc + $r * cos( $arc * $_ ), $yc + $r * sin( $arc * $_ ) ],
		0 .. $points - 1;


	foreach my $i ( 0 .. $#points ) {
		$pdf->lines(
			@{ $points[$i]   },
			@{ $points[$i-1] },
			);
		}

	}

sub arrow_factor { 15 }

sub arrow_length {
	my( $pdf, $base ) = @_;

	if( defined $base ) { $base + $pdf->arrow_factor; }
	else { 85 }

	}


sub arrow_angle  { 0 }

=item arrowhead_length

=item arrowhead_width

=cut

sub arrowhead_length { 10 }
sub arrowhead_width  {  5 }

sub make_reference_arrow {
	my( $pdf, $start, $target ) = @_;

	my($angle, $length) = $start->angle_length_to($target);

	my $L = $pdf->arrowhead_length;
	my $W = $pdf->arrowhead_width;

	my $arrow_retro_tip_high = $target
		->clone
		->add(
			- $L * cos($angle) - $W * sin($angle),
			- $L * sin($angle) + $W * cos($angle)
			);

	my $arrow_retro_tip_low = $target
		->clone
		->add(
			- $L * cos($angle) + $W * sin($angle),
			- $L * sin($angle) - $W * cos($angle)
			);

	$pdf->lines_xy( $start, $target );

 	$pdf->filledPolygon(
 		$target->xy,
 		$arrow_retro_tip_high->xy,
 		$arrow_retro_tip_low->xy,
 		);

  	return $target;
	}

sub lines_xy {
	my( $pdf, $start, $end ) = @_;

	$pdf->SUPER::lines(
		$start->xy,
		$end->xy,
		);
	}

sub make_reference_icon {
	my( $pdf, $center ) = @_;

	$pdf->make_magic_circle(
		$center,
		$pdf->box_height / 6,
		);

	$center;
	}

=for comment

http://www.adobe.com/devnet/acrobat/pdfs/PDF32000_2008.pdf

sub make_circle
	{
	my( $pdf, $x, $y, $radius, $start_angle, $end_angle ) = @_;

	# theta is sweep, which is 360

	my $Pi2 = 3.1415926 * 2;

	my( $x0, $y0 ) = ( cos( 180 / $Pi2 ), sin( 180 / $Pi2 ) );
	my( $x1, $y1 ) = ( (4 - $x0) / 3, (1-$x0)*(3-$x0)/(3*$y0) )
	my( $x2, $y2 ) = ( $x1, -$y0 );
	my( $x3, $y3 ) = ( $x1, -$y1 );

	$pdf->{stream} .= <<"PDF";
$x $y m
$x1 $y1 $x2 $y2 $x3 $y3 c


PDF


	}

=cut

sub make_scalar {
	my( $pdf, $name, $value, $bottom_left_x, $bottom_left_y ) = @_;

	my $length = max( map { length $_ } $name, $$value );

	my $scalar_width  = $pdf->font_width * $length;
	my $scalar_height = 10;

	$pdf->make_pointy_box(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width + 2 * $pdf->x_padding,
		$pdf->box_height,
		$name
		);

	$pdf->lines(
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y,
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y - 10,
		);

	$pdf->make_text_box(
		$bottom_left_x,
		$bottom_left_y - 10 - $pdf->font_height - 2 * $pdf->y_padding,
		$scalar_width  + 2 * $pdf->x_padding,
		$pdf->box_height,
		$value
		);
	}

sub make_array {
	my( $pdf, $name, $array, $bottom_left_x, $bottom_left_y ) = @_;

	my $length = max( map { length $_ } $name, grep { ! ref $_ } @$array );

	my $scalar_width  = $pdf->font_width * $length;

	$pdf->make_pointy_box(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width +  2 * $pdf->x_padding,
		$pdf->box_height,
		$name
		);

	$pdf->lines(
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y,
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y - $pdf->connector_height,
		);

	$pdf->make_list(
		$array,
		$bottom_left_x,
		$bottom_left_y - $pdf->connector_height - $pdf->black_bar_height,
		$scalar_width + 2 * $pdf->x_padding
		);

	}

sub make_list {
	my( $pdf, $array, $bottom_left_x, $bottom_left_y, $width ) = @_;
	return if exists $pdf->{refs}{ "$array" };

	my $scalar_width = $width || $pdf->get_list_width( $array );

	$pdf->make_collection_bar(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width + $pdf->pointy_width + $pdf->x_padding,
		);

	$pdf->{refs}{ "$array" } = XYPoint->new(
		$bottom_left_x,
		$bottom_left_y + $pdf->box_height / 2
		);

	my $count = 0;
	foreach my $value ( @$array ) {
		$count++;

		my $box_value = ref $value ? '' : $value;
		$pdf->make_text_box(
			$bottom_left_x,
			$bottom_left_y - $count*($pdf->font_height + 2 * $pdf->y_padding),
			$scalar_width  + $pdf->x_padding,
			$pdf->box_height,
			\ $box_value
			);

		if( ref $value ) {
			my $center = XYPoint->new(
				$bottom_left_x + ( $scalar_width + $pdf->x_padding )/2 + $pdf->x_padding,
				$bottom_left_y + $pdf->box_height / 2 - $count*$pdf->box_height,
				);

			my $target = $pdf->{refs}{ "$value" } //
				XYPoint->new(
					$center->x + $pdf->arrow_length( $scalar_width + $pdf->x_padding ),
					$center->y, # ,,
					);

			$pdf->make_reference_icon( $center );

			my $arrow_end = $pdf->make_reference_arrow(
				$center,
				$target,
				);

			my $ref_start = $arrow_end->clone;
			$ref_start->add_y( - $pdf->black_bar_height / 2 );

			if( ref $value eq ref [] ) {
				$pdf->make_list( $value, $ref_start->xy );
				}
			elsif( ref $value eq ref {} ) {
				$pdf->make_anonymous_hash( $value, $ref_start->xy );
				}
			}
		}

	}

sub get_list_height {
	my( $pdf, $array ) = @_;

	}

sub minimum_scalar_width { 3 * $_[0]->font_width }

sub get_list_width {
	my( $pdf, $array ) = @_;

	my $length = max( map { length $_ }  grep { ! ref $_ } @$array );

	my $scalar_width  = max( $pdf->minimum_scalar_width, $pdf->font_width * $length );
	}

sub make_hash {
	my( $pdf, $name, $hash, $bottom_left_x, $bottom_left_y ) = @_;

	my( $key_length, $value_length ) = $pdf->get_hash_lengths( $hash );

	my $scalar_width  = $pdf->font_width * ( $key_length + $value_length ) + 4 * $pdf->x_padding + $pdf->pointy_width;

	$pdf->make_pointy_box(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width,
		$pdf->box_height,
		$name
		);

	$pdf->lines(
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y,
		( $bottom_left_x + $pdf->x_padding + $scalar_width / 2 ), $bottom_left_y - $pdf->connector_height,
		);

	$pdf->make_anonymous_hash(
		$hash,
		$bottom_left_x,
		$bottom_left_y - $pdf->connector_height - $pdf->black_bar_height,
		);

	}

sub get_hash_lengths {
	my( $pdf, $hash ) = @_;

	my $key_length   = max( map { length $_ } keys %$hash );
	my $value_length = max( map { length $_ } grep { ! ref $_ } values %$hash );

	( $key_length, $value_length );
	}

sub make_anonymous_hash {
	my( $pdf, $hash, $bottom_left_x, $bottom_left_y ) = @_;

	my( $key_length, $value_length ) = $pdf->get_hash_lengths( $hash );

	my $scalar_width  =
		$pdf->font_width * ( $key_length + $value_length ) +
		4 * $pdf->x_padding                                +
		$pdf->pointy_width;

	$pdf->make_collection_bar(
		$bottom_left_x,
		$bottom_left_y,
		$scalar_width + $pdf->pointy_width,
		);

	my $count = 0;
	foreach my $key ( keys %$hash ) {
		$count++;

		my $key_box_width =
			$pdf->font_width * $key_length + 1 * $pdf->x_padding + $pdf->pointy_width / 2;

			; # share name box extra

		$pdf->make_pointy_box(
			$bottom_left_x,
			$bottom_left_y - $count*($pdf->font_height + 2 * $pdf->y_padding),
			$key_box_width,
			$pdf->box_height,
			$key
			);

		$pdf->make_text_box(
			$bottom_left_x + $key_box_width + $pdf->pointy_width + 2 * $pdf->stroke_width,
			$bottom_left_y - $count*($pdf->font_height + 2 * $pdf->y_padding),
			$pdf->font_width * $value_length + $pdf->x_padding - 2.125*$pdf->stroke_width,
			$pdf->box_height,
			\ $hash->{$key}
			);
		}

	}

sub make_collection_bar {
	my( $pdf, $bottom_left_x, $bottom_left_y, $width ) = @_;

	my $height = $pdf->black_bar_height;

	$pdf->filledRectangle(
		$bottom_left_x - $pdf->stroke_width,
		$bottom_left_y,
		$width + 2 * $pdf->stroke_width,
		$height,
		);

	$pdf->strokePath;
	}

sub make_text_box {
	my( $pdf, $bottom_left_x, $bottom_left_y, $width, $height, $text ) = @_;

	$pdf->rectangle(
		$bottom_left_x,
		$bottom_left_y,
		$width + $height/2 * sqrt(2),
		$height,
		);

	$pdf->text(
		$bottom_left_x + $pdf->x_padding,
		$bottom_left_y + $pdf->y_padding,
		ref $text ? $$text : $text
		);

	}

sub make_pointy_box {
	my( $pdf, $bottom_left_x, $bottom_left_y, $width, $height, $text ) = @_;

	my $point_y = $bottom_left_y + $height / 2;
	my $point_x = $bottom_left_x + $width + $height/2 * sqrt(2);

	my @vertices = (
		$bottom_left_x,          $bottom_left_y,
		$bottom_left_x + $width, $bottom_left_y,
		$point_x,             $point_y,
		$bottom_left_x + $width, $bottom_left_y + $height,
		$bottom_left_x         , $bottom_left_y + $height
		);

	$pdf->polygon( @vertices );

	$pdf->text(
		$bottom_left_x + $pdf->x_padding,
		$bottom_left_y + $pdf->y_padding,
		$text
		);

	}

=back

=head1 TO DO

Everything.

=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/pegs-pdf/

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut


BEGIN {
	package XYPoint;
	use POSIX qw(atan);

	use constant π => 3.1415926;

	sub new { bless [ @_[1,2] ], $_[0] }
	sub x { $_[0][0] }
	sub y ###
		{ $_[0][1] }

	sub add ($self, $delta_x, $delta_y) {
		$self->add_x( $delta_x );
		$self->add_y( $delta_y );
		$self;
		}
	sub add_x ($self, $delta_x) { $self->[0] += $delta_x; $self }
	sub add_y ($self, $delta_y) { $self->[1] += $delta_y; $self }

	sub angle_length_to {
		my( $self, $target ) = @_;

		my $h = $target->y - $self->y; # -
		my $b = $target->x - $self->x;

		if( $b == 0 ) {
			my $sign = $h > 0 ? 1 : -1;
			return ( $sign * 1/2 * π, abs($h) );
			}

		my $ratio = $h / $b;

		say STDERR "H: $h B: $b";
		my $angle = atan( $ratio );
		say STDERR "angle before: $angle";

		   if( $b < 0 and $h < 0 ) { $angle -= π }
		elsif( $b < 0 and $h >= 0 ) { $angle += π }

		say STDERR "angle after: $angle";

		my $length = sqrt( $b**2 + $h**2 );
		($angle, $length);
		}

	sub rotate ( $self, $angle ) {
		}

	sub xy { ( $_[0]->x, $_[0]->y ) }

	sub clone { (ref $_[0])->new( $_[0]->xy ) }

	sub as_string { sprintf "(%d, %d)", $_[0]->x, $_[0]->y }
	}

1;
