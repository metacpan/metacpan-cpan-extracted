package Term::Fabulous::Widget::PieChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Chart;

class Term::Fabulous::Widget::PieChart
	:isa(Term::Fabulous::Widget::Chart)
	:strict(params)
{
	use Carp qw(croak);
	use List::Util qw(max min sum0 first);
	use POSIX qw(floor ceil);
	use Scalar::Util qw(looks_like_number);
	use Term::Fabulous::Check qw(boolean describe one_of);
	use Term::Fabulous::Chart::Format qw(format_value check_number_format);
	use Term::Fabulous::Chart::Marker;
	use Term::Fabulous::Chart::Palette qw(chart_color contrast_rgb mix_rgb);
	use Term::Fabulous::Chart::Radial qw(CELL_ASPECT TAU circle_frame polar_of point_at);
	use Term::Fabulous::Chart::Raster;
	use Term::Fabulous::Chart::Surface;
	use Term::Fabulous::Termbox qw(TB_BOLD);

	use constant {
		GAP_WIDTH               => 0.3,    # cell widths between two slices, at least a subpixel
		OTHER                   => "\0other",
		LABEL_ROOM              => 1,    # columns free around a slice label
		LEGEND_PERCENT_DECIMALS => 0,
	};

	my @SORT          = qw(none desc asc);
	my @SLICE_LABELS  = qw(percent value label none);
	my @LEGEND_VALUES = qw(percent value both none);
	my @PIE_MARKERS   = qw(quadrant half sextant braille);

	field $initial_data   :param(data)   = [];
	field $initial_labels :param(labels) = undef;
	field $initial_colors :param(colors) = undef;
	field $hole           :param         = undef;
	field $start_angle    :param         = 0;
	field $sort           :param         = 'none';
	field $slice_labels   :param         = undef;
	field $legend_values  :param         = undef;
	field $center_text    :param         = undef;
	field $marker         :param         = 'quadrant';
	field $other          :param         = 0;
	field $other_label    :param         = 'Other';
	field $gap            :param         = 0;
	field $format         :param         = undef;

	field @_slices;    # { label, value, color, opacity, slot }
	field %_slice_by_label;
	field $_next_slot = 0;

	ADJUST {
		$hole          //= $self->default_hole;
		$slice_labels  //= $self->default_slice_labels;
		$legend_values //= $self->default_legend_values;
		$hole          = $self->_checked_hole($hole);
		$start_angle   = $self->_checked_angle($start_angle);
		$sort          = one_of( $self, sort          => $sort,          @SORT );
		$slice_labels  = one_of( $self, slice_labels  => $slice_labels,  @SLICE_LABELS );
		$legend_values = one_of( $self, legend_values => $legend_values, @LEGEND_VALUES );
		$marker        = $self->_checked_marker($marker);
		$other         = $self->_checked_fraction( other => $other );
		$gap           = boolean( $self, gap => $gap );
		$format        = check_number_format( ref $self, 'format', $format );
		$self->_check_title( center_text => $center_text );
		$other_label = $self->_check_title( other_label => $other_label ) // 'Other';
		$self->set_data( $initial_data, $initial_labels, $initial_colors );
		( $initial_data, $initial_labels, $initial_colors ) = ();
	}

	# A pie has no hole and shows percentages on its slices and in the
	# legend.
	method default_hole ()          { return 0 }
	method default_slice_labels ()  { return 'percent' }
	method default_legend_values () { return 'percent' }

	method _checked_hole ($value) {
		$self->_fail( 'hole', 'a number from 0 to 0.9', $value ) unless defined $value && !ref $value && looks_like_number($value) && $value >= 0 && $value <= 0.9;
		return $value + 0;
	}

	method _checked_angle ($value) {
		$self->_fail( 'start_angle', 'a number of degrees', $value ) unless defined $value && !ref $value && looks_like_number($value) && $value == $value && $value - $value == 0;
		return $value + 0;
	}

	method _checked_marker ($value) {
		$self->_fail( 'marker', join( ', ', @PIE_MARKERS ), $value ) unless defined $value && !ref $value && grep { $_ eq $value } @PIE_MARKERS;
		return $value;
	}

	method _checked_value ( $label, $value ) {
		croak ref($self) . ": the value of slice '$label' must be a number of at least 0, got " . describe($value)
			unless defined $value && !ref $value && looks_like_number($value) && $value == $value && $value - $value == 0 && $value >= 0;
		return $value + 0;
	}

	# ---------------------------------------------------------------------
	# Slices
	# ---------------------------------------------------------------------

	# A new slice hash; a label the chart knows keeps its palette slot
	# (its color), a new label gets one from _place.
	method _slice ( $label, $value, $color ) {
		croak ref($self) . ": a slice label must be a non-empty string, got " . describe($label) unless defined $label && !ref $label && length $label;
		my $known = $_slice_by_label{$label};
		my %slice = ( label => "$label", slot => $known ? $known->{slot} : undef, value => $self->_checked_value( $label, $value ) );
		( $slice{color}, $slice{opacity} ) = defined $color ? chart_color( $self, "color of slice '$label'", $color ) : ( undef, 1 );
		return \%slice;
	}

	# Makes checked slices the chart's; new labels take the next slots.
	method _place (@slices) {
		$_->{slot} //= $_next_slot++ foreach @slices;
		@_slices         = @slices;
		%_slice_by_label = map { $_->{label} => $_ } @_slices;
		$self->_end_gone_hover;
		$self->mark_changed;
		return $self;
	}

	# A hover on a slice the chart no longer has ends; the folded slice
	# stays while small slices can fold.
	method _end_gone_hover () {
		$self->end_hover_unless_shown( ( map { $_->{label} } @_slices ), ( $other > 0 ? $other_label : () ) );
		return;
	}

	# data: numbers (named by labels), [ label, value ] pairs, or
	# { label, value, color } hashes.
	method set_data ( $data, $labels = undef, $colors = undef ) {
		croak ref($self) . ": data must be an array reference, got " . describe($data) unless ref $data eq 'ARRAY';
		croak ref($self) . ": labels must be an array reference, got " . describe($labels) if defined $labels && ref $labels ne 'ARRAY';
		croak ref($self) . ": colors must be an array reference, got " . describe($colors) if defined $colors && ref $colors ne 'ARRAY';
		my @slices;
		foreach my $index ( 0 .. $#$data ) {
			my $item = $data->[$index];
			my ( $label, $value, $color );
			if ( ref $item eq 'ARRAY' ) {
				croak ref($self) . ": slice $index must be [ label, value ], got an array of " . scalar(@$item) . " values" unless @$item == 2;
				( $label, $value ) = @$item;
			}
			elsif ( ref $item eq 'HASH' ) {
				my @unknown = grep { !/\A(?:label|value|color)\z/ } sort keys %$item;
				croak ref($self) . ": slice $index takes only label, value and color, got @unknown" if @unknown;
				( $label, $value, $color ) = @$item{qw(label value color)};
			}
			else {
				( $label, $value ) = ( $labels && defined $labels->[$index] ? $labels->[$index] : 'Slice ' . ( $index + 1 ), $item );
			}
			$color //= $colors->[$index] if $colors;
			croak ref($self) . ": two slices are labeled '$label'" if grep { $_->{label} eq ( $label // '' ) } @slices;
			push @slices, $self->_slice( $label, $value, $color );
		}
		return $self->_place(@slices);
	}

	method set_value ( $label, $value ) {
		my $known = $_slice_by_label{ $label // '' };
		return $self->add_slice( $label, $value ) unless $known;
		$known->{value} = $self->_checked_value( $label, $value );
		$self->mark_changed;
		return $self;
	}

	method add_slice ( $label, $value, $color = undef ) {
		croak ref($self) . ": a slice labeled '$label' exists already" if defined $label && $_slice_by_label{$label};
		return $self->_place( @_slices, $self->_slice( $label, $value, $color ) );
	}

	method remove_slice (@labels) {
		foreach my $label (@labels) {
			croak ref($self) . ": no slice labeled " . describe($label) unless defined $label && $_slice_by_label{$label};
		}
		my %gone = map { $_ => 1 } @labels;
		@_slices = grep { !$gone{ $_->{label} } } @_slices;
		delete @_slice_by_label{@labels};
		$self->_end_gone_hover;
		$self->mark_changed;
		return $self;
	}

	method clear_slices () {
		@_slices         = ();
		%_slice_by_label = ();
		$self->_end_gone_hover;
		$self->mark_changed;
		return $self;
	}

	method set_slice_color ( $label, $color ) {
		my $slice = $_slice_by_label{ $label // '' } // croak ref($self) . ": no slice labeled " . describe($label);
		( $slice->{color}, $slice->{opacity} ) = defined $color ? chart_color( $self, "color of slice '$label'", $color ) : ( undef, 1 );
		$self->mark_changed;
		return $self;
	}

	method slices () {
		return map { { label => $_->{label}, value => $_->{value}, ( defined $_->{color} ? ( color => sprintf '#%06x', $_->{color} ) : () ) } } @_slices;
	}

	method value ($label) {
		my $slice = $_slice_by_label{ $label // '' } // return undef;
		return $slice->{value};
	}

	method total () {
		return sum0 map { $_->{value} } @_slices;
	}

	# The slices as drawn: sorted, small ones folded into "Other", each
	# with its share of the total.
	method shown_slices ($look) {
		my @slices = grep { $_->{value} > 0 } @_slices;
		@slices = sort { $b->{value} <=> $a->{value} } @slices if $sort eq 'desc';
		@slices = sort { $a->{value} <=> $b->{value} } @slices if $sort eq 'asc';
		my $total = sum0 map { $_->{value} } @slices;
		return () unless $total > 0;
		my @shown = map {
			{ %$_, share => $_->{value} / $total }
		} @slices;
		if ( $other > 0 ) {
			my @small = grep { $_->{share} < $other } @shown;
			if ( @small >= 2 ) {
				my %small = map { $_->{label} => 1 } @small;
				@shown = grep { !$small{ $_->{label} } } @shown;
				my $value = sum0 map { $_->{value} } @small;
				push @shown, { label => $other_label, value => $value, share => $value / $total, color => mix_rgb( $look->{label}, $look->{base}, 0.35 ), opacity => 1, is_other => 1 };
			}
		}
		foreach my $slice (@shown) {
			my $color = $slice->{color} // $self->slot_color( $look, $slice->{slot} );
			$color               = mix_rgb( $look->{base}, $color, $slice->{opacity} ) if $slice->{opacity} < 1;
			$slice->{base_color} = $color;
			$slice->{shown}      = $self->shown_color( $look, $slice->{label}, $color );
		}
		return @shown;
	}

	# ---------------------------------------------------------------------
	# Drawing
	# ---------------------------------------------------------------------

	method default_legend_position () {
		return 'right';
	}

	method _value_text ($value) {
		return format_value( $value, $format );
	}

	method _percent_text ($share) {
		my $percent = $share * 100;
		return ( $percent > 0 && $percent < 1 ? '<1' : sprintf( '%.0f', $percent ) ) . '%';
	}

	method legend_entries ($look) {
		return map {
			my $slice = $_;
			my $value
				= $legend_values eq 'percent' ? $self->_percent_text( $slice->{share} )
				: $legend_values eq 'value'   ? $self->_value_text( $slice->{value} )
				: $legend_values eq 'both'    ? [ $self->_value_text( $slice->{value} ), $self->_percent_text( $slice->{share} ) ]
				:                               undef;
			{ series => $slice->{label}, label => $slice->{label}, color => $slice->{base_color}, symbol => 'fill', value => $value, raw_value => $slice->{value} }
		} $self->shown_slices($look);
	}

	# The angles [from, to) of each slice in turns, and how far out it
	# reaches (1 is the full radius).
	method slice_geometry ( $look, @slices ) {
		my $at = 0;
		return map {
			my $from = $at;
			$at += $_->{share};
			[ $from, $at, 1 ];
		} @slices;
	}

	method draw_plot ( $surface, $x, $y, $width, $height, $look ) {
		my @slices = $self->shown_slices($look);
		my $circle = circle_frame( 0, 0, $width, $height, 0.5 );
		return unless @slices && $circle->{radius} >= 1;
		$self->draw_background_grid( $surface, $x, $y, $width, $height, $circle, $look, \@slices );

		my @geometry = $self->slice_geometry( $look, @slices );
		my $start    = $start_angle / 360;
		my $radius   = $circle->{radius};
		my $inner    = $hole * $radius;
		my @targets  = map { $self->register_target( series => $slices[$_]{label}, index => $_, label => $slices[$_]{label}, value => $slices[$_]{value} ) } 0 .. $#slices;

		my $raster = Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named($marker), columns => $width, rows => $height );
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		my $gaps = $gap && @slices > 1;

		# At least a subpixel wide in both directions, so it shows at any
		# resolution: a subpixel whose center lies on the gap's edge is out.
		my $gap_width = max( GAP_WIDTH, 1 / $sx, CELL_ASPECT / $sy );
		$raster->paint_area(
			0, 0,
			$raster->width,
			$raster->height,
			sub ( $px, $py ) {
				my ( $distance, $angle ) = polar_of( $circle, ( $px + 0.5 ) / $sx, ( $py + 0.5 ) / $sy, $start );
				return () if $distance < $inner || $distance > $radius;
				my $index = first { $angle >= $geometry[$_][0] && $angle < $geometry[$_][1] } 0 .. $#geometry;
				return () unless defined $index;
				my ( $from, $to, $reach ) = $geometry[$index]->@*;
				return () if $distance > $reach * $radius;
				if ($gaps) {
					my $turns = min( $angle - $from, $to - $angle, 0.25 );
					my $away  = sin( $turns * TAU ) * $distance;    # from the nearer edge of the slice
					return () if $away <= $gap_width / 2 + 1e-9;
				}
				return ( $slices[$index]{shown}, $targets[$index] );
			}
		);
		$surface->composite( $raster, 'fill', $x, $y );

		$self->_draw_slice_labels( $surface, $x, $y, $circle, \@slices, \@geometry, $look, $start, $inner ) if $slice_labels ne 'none';
		$self->_draw_center( $surface, $x, $y, $circle, \@slices, $look, $inner ) if $inner >= 3;
		$self->draw_foreground_grid( $surface, $x, $y, $width, $height, $circle, $look, \@slices );
		return;
	}

	# Hooks for charts that draw rings or labels around the slices.
	method draw_background_grid ( $surface, $x, $y, $width, $height, $circle, $look, $slices ) { return }
	method draw_foreground_grid ( $surface, $x, $y, $width, $height, $circle, $look, $slices ) { return }

	# The percentage (value, label) on each slice that has room for it.
	method _draw_slice_labels ( $surface, $x, $y, $circle, $slices, $geometry, $look, $start, $inner ) {
		foreach my $index ( 0 .. $#$slices ) {
			my $slice = $slices->[$index];
			my ( $from, $to, $reach ) = $geometry->[$index]->@*;
			my $outer = $reach * $circle->{radius};
			next if $outer - $inner < 2;
			my $text
				= $slice_labels eq 'percent' ? $self->_percent_text( $slice->{share} )
				: $slice_labels eq 'value'   ? $self->_value_text( $slice->{value} )
				:                              $slice->{label};
			my $width    = Term::Fabulous::Chart::Surface->text_columns($text);
			my $distance = $inner + ( $outer - $inner ) * ( $inner ? 0.5 : 0.6 );
			my ( $center_x, $center_y ) = point_at( $circle, $distance, ( $from + $to ) / 2, $start );
			my ( $column, $row )        = ( floor( $center_x - $width / 2 + 0.5 ), floor($center_y) );

			# Only where the text and a cell around it lie inside the slice.
			my $fits = 1;
			foreach my $cell ( $column - LABEL_ROOM .. $column + $width - 1 + LABEL_ROOM ) {
				my ( $distance_of_cell, $angle ) = polar_of( $circle, $cell + 0.5, $row + 0.5, $start );
				$fits = 0 unless $distance_of_cell >= $inner && $distance_of_cell <= $outer - 0.5 && $angle >= $from && $angle < $to;
			}
			next unless $fits;
			$surface->text( $x + $column, $y + $row, $text, contrast_rgb( $slice->{shown} ), bg => $slice->{shown} );
		}
		return;
	}

	# In the hole of a donut: the center_text, or the slice the pointer
	# is on, or the total.
	method _draw_center ( $surface, $x, $y, $circle, $slices, $look, $inner ) {
		return if defined $center_text && !length $center_text;
		my $hovered = defined $look->{emphasis} ? first { $_->{label} eq $look->{emphasis} } @$slices : undef;
		my @lines
			= defined $center_text ? ( split /\n/, $center_text )
			: $hovered             ? ( $self->_percent_text( $hovered->{share} ), $hovered->{label} )
			:                        ( $self->_value_text( sum0 map { $_->{value} } @$slices ), 'Total' );
		my $room = floor( 2 * $inner / sqrt 2 ) - 1;
		my $top  = floor( $circle->{center_y} - @lines / 2 + 0.5 );
		foreach my $index ( 0 .. $#lines ) {
			my $line  = $lines[$index];
			my $width = min( Term::Fabulous::Chart::Surface->text_columns($line), $room );
			next if $width < 1;
			my $color = $index == 0 ? $look->{title} : $look->{label};
			$surface->text( $x + floor( $circle->{center_x} - $width / 2 + 0.5 ), $y + $top + $index, $line, $color, max => $room, flags => $index == 0 ? TB_BOLD : 0 );
		}
		return;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $value;
	}

	method hole          (@new) { return @new ? $self->_set( \$hole, $self->_checked_hole( $new[0] ) )                                    : $hole }
	method start_angle   (@new) { return @new ? $self->_set( \$start_angle, $self->_checked_angle( $new[0] ) )                            : $start_angle }
	method sort          (@new) { return @new ? $self->_set( \$sort, one_of( $self, sort => $new[0], @SORT ) )                            : $sort }
	method slice_labels  (@new) { return @new ? $self->_set( \$slice_labels, one_of( $self, slice_labels => $new[0], @SLICE_LABELS ) )    : $slice_labels }
	method legend_values (@new) { return @new ? $self->_set( \$legend_values, one_of( $self, legend_values => $new[0], @LEGEND_VALUES ) ) : $legend_values }
	method center_text   (@new) { return @new ? $self->_set( \$center_text, $self->_check_title( center_text => $new[0] ) )               : $center_text }
	method marker        (@new) { return @new ? $self->_set( \$marker, $self->_checked_marker( $new[0] ) )                                : $marker }
	method other         (@new) { return @new ? $self->_set( \$other, $self->_checked_fraction( other => $new[0] ) )                      : $other }
	method other_label   (@new) { return @new ? $self->_set( \$other_label, $self->_check_title( other_label => $new[0] ) // 'Other' )    : $other_label }
	method gap           (@new) { return @new ? $self->_set( \$gap, boolean( $self, gap => $new[0] ) )                                    : $gap }
	method format        (@new) { return @new ? $self->_set( \$format, check_number_format( ref $self, 'format', $new[0] ) )              : $format }

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			hole          => 'scalar',
			start_angle   => 'scalar',
			sort          => 'scalar',
			slice_labels  => 'scalar',
			legend_values => 'scalar',
			center_text   => 'scalar',
			marker        => 'scalar',
			other         => 'scalar',
			other_label   => 'scalar',
			gap           => 'boolean',
			format        => 'scalar',
			slice         => \&_parse_slice,
		);
	}

	# slice "Rent" 1200 color="#3987e5"
	method _parse_slice ($kid) {
		my @args  = map { $_->as_perl } $kid->args->@*;
		my $props = { map { $_->[0] => $_->[1]->as_perl } $kid->props->@* };
		croak ref($self) . ": layout property 'slice' takes a label and a value" unless @args == 2 && !$kid->children->@*;
		my @unknown = grep { $_ ne 'color' } sort keys %$props;
		croak ref($self) . ": layout property 'slice' takes only the property color, got @unknown" if @unknown;
		$self->add_slice( "$args[0]", $args[1], $props->{color} );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::PieChart - A pie chart: parts of a whole as slices

=head1 SYNOPSIS

	use Term::Fabulous::Widget::PieChart;

	my $chart = Term::Fabulous::Widget::PieChart->new(
		title => 'Visitors by browser',
		sort  => 'desc',                       # the largest slice first
		other => 0.03,                         # slices below 3% fold into "Other"
		data  => [
			[ Chrome  => 6420 ],
			[ Safari  => 1830 ],
			[ Firefox => 1210 ],
			[ Edge    => 980 ],
			[ Opera   => 160 ],
			[ Vivaldi => 90 ],
		],
	);

	$chart->set_value( Chrome => 6500 );
	$chart->add_slice( Brave => 120, '#f5a623' );
	$chart->remove_slice('Opera');
	say $chart->total;

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-pie-chart.svg" alt="A pie of browser shares with the percentage on each slice and a legend on the right, small browsers folded into Other"></p>

=end html

F<examples/widgets/pie-chart.pl> draws this chart.

=head1 DESCRIPTION

A pie chart shows how a whole divides into parts: each slice's angle is
its share of the total. The slices go clockwise from 12 o'clock
(C<start_angle> turns them), in the order given or sorted by value, each
with the next color of the palette. The pie is as large a circle as the
room allows, drawn in quadrant blocks (two by two per cell; C<marker>
chooses finer characters), with its share written on every slice that
has room for it and a legend on the right that lists the slices with
their shares. The slices are the "series" of this chart: hover
emphasizes one and fades the others, and C<SeriesHover> reports its
label and value.

Pies read well with up to about six slices. C<other> folds the small
ones into one slice labeled C<other_label>, when at least two are below
that share; that slice comes last and is gray. Slices with a value of 0
are neither drawn nor listed in the legend.

=head2 Styles

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-pie-chart-styles.svg" alt="Four pies of the same budget: in quadrant blocks with percentages, in sextants with gaps between the slices, in Braille dots with the slice labels, and in half blocks with the values, sorted ascending and starting at 3 o'clock"></p>

=end html

F<examples/widgets/pie-chart-styles.pl> draws the same slices four
ways. C<marker> chooses the characters: C<quadrant> blocks (2 x 2
subpixels per cell, the default), C<sextant> (2 x 3), C<braille> dots (2
x 4, finest, but one color per cell, so slice edges look dotted) or
C<half> blocks (1 x 2). C<gap> separates the slices by a thin line of
background. C<slice_labels> writes the share, the value or the label on
each slice that has room for it, C<sort> orders the slices by value, and
C<start_angle> turns the whole pie.

L<Term::Fabulous::Widget::DonutChart> is a pie with a hole for a text in
the middle; L<Term::Fabulous::Widget::PolarAreaChart> gives every slice
the same angle and shows the value as its length.

=head2 Data

	data => [ 6420, 1830 ], labels => [ 'Chrome', 'Safari' ], colors => [ '#3987e5', '#d95926' ]
	data => [ [ Chrome => 6420 ], [ Safari => 1830 ] ]
	data => [ { label => 'Chrome', value => 6420, color => '#3987e5' } ]

A slice has a label (unique, not empty), a value (a number of at least
0) and optionally a color; give the data as plain values (named by
C<labels>, else C<Slice 1>, C<Slice 2>, ...), as C<[ label, value ]>
pairs, or as hashes. C<colors> names the colors of the plain or pair
forms by position.

A slice keeps its palette color for as long as its label is in the
chart, also when other slices come and go and when C<set_data> replaces
the data; so a slice stays recognizable while its value changes. A label
that is removed and added again gets the next free color.

Invalid data dies with a message that names the slice, for example
C<the value of slice 'Chrome' must be a number of at least 0, got '-5'>,
and so does a label used twice.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::PieChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::Chart/CONSTRUCTOR> (the
legend is on the C<right> by default), and:

=over

=item C<data>, C<labels>, C<colors>

The slices; see L</Data>. Default: none.

=item C<hole>

A number from 0 to 0.9: the radius of the hole in the middle as a share
of the pie's radius. Default: 0 (0.6 for a donut). A hole whose radius
is at least three cell widths shows a text; see C<center_text>.

=item C<start_angle>

Degrees clockwise from 12 o'clock where the first slice starts. Default:
0.

=item C<sort>

C<none> (the default: the order given), C<desc> (the largest first) or
C<asc>.

=item C<slice_labels>

What is written on the slices: C<percent> (the default), C<value>,
C<label> or C<none>. A text is only written where it fits inside its
slice.

=item C<legend_values>

What the legend shows right of each label: C<percent> (the default),
C<value>, C<both> (the value and the share, in aligned columns) or
C<none>.

=item C<center_text>

For a chart with a hole (a donut): the text in the hole, lines separated
by newlines; the first line is bold. Default: C<undef>, which shows the
total with the word C<Total> below it, or, while a slice is emphasized
(by the pointer or by C<highlight>), its share and label. An empty
string shows nothing. Lines longer than the hole is wide are cut.

=item C<marker>

C<quadrant> (the default), C<half>, C<sextant> or C<braille>: the
characters the slices are drawn with. Sextants are smoother; Braille
dots are finest but show one color per cell.

=item C<other>

A share from 0 to 1. Slices below it are folded into one slice when at
least two of them exist. Default: 0 (never).

=item C<other_label>

The label of that slice; C<undef> means the default, C<Other>.

=item C<gap>

A boolean: a thin gap between the slices. Default: false. The gap is at
least one subpixel of the marker wide, so it is finest with C<sextant>
or C<braille>.

=item C<format>

How values are written (on slices, in the legend, in the center): a
format of L<Term::Fabulous::Chart::Format>: C<si>, C<integer>,
C<percent>, a C<sprintf> format such as C<'%d €'>, or a code reference
that gets the value and returns the text. Default: C<undef>, up to two
decimals (three significant digits below 1) and SI prefixes from a
million on (C<1.2M>). Shares are always written as whole percentages,
C<< <1% >> for a share below one percent.

=back

=head1 METHODS

Every parameter except the data has an accessor of the same name:
without an argument it returns the value, with one it checks and sets
it; an invalid value dies and changes nothing. The chart shows every
change in the next frame.

	$chart->sort('desc');
	$chart->slice_labels('value');
	$chart->hole(0.5);

=head2 set_data

	$chart->set_data( \@data, \@labels, \@colors );

Replaces all slices; see L</Data>. Dies without changing anything for
invalid data. When the mouse pointer is on a slice whose label is gone,
the hover ends (see L<Term::Fabulous::Widget::Chart/Hover and emphasis>).

=head2 set_value

	$chart->set_value( Chrome => 6500 );

Changes a slice's value; adds the slice when the label is new. Returns
the chart.

=head2 add_slice, remove_slice, clear_slices

	$chart->add_slice( $label, $value, $color );
	$chart->remove_slice( 'Opera', 'Vivaldi' );
	$chart->clear_slices;

C<add_slice> adds a slice at the end (the color is optional) and dies
when the label exists already. C<remove_slice> removes the slices with
these labels and dies, removing none, when one of them does not exist.
C<clear_slices> removes all. They return the chart. Removing the slice
the mouse pointer is on ends the hover.

=head2 set_slice_color

	$chart->set_slice_color( Chrome => '#4285f4' );

A color, or C<undef> for the palette color again. Dies for an unknown
label.

=head2 slices, value, total

	my @slices = $chart->slices;    # ( { label => 'Chrome', value => 6420, color => '#3987e5' }, ... )
	my $value  = $chart->value('Chrome');
	my $total  = $chart->total;

The slices as given, in their order (C<color> only when the slice has
one of its own, as a C<#rrggbb> string), the value of one slice
(C<undef> for an unknown label), and the sum of all values.

Also C<hovered>, C<revision> and C<effective_background> from
L<Term::Fabulous::Widget::Chart>.

=head1 EVENTS

C<SeriesHover> (L<Term::Fabulous::Event::SeriesHover>) when the pointer
moves onto another slice or legend entry, or away. The series and the
label are the slice's label (C<other_label> for the folded slice), the
value is its value, and on a slice the index is its position among the
slices as drawn (after sorting and folding, from 0).

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::PieChart as PieChart

	PieChart "browsers" {
		title "Visitors by browser"
		sort "desc"
		other 0.03
		other_label "Rest"
		slice_labels "percent"
		legend_values "both"
		legend "bottom"
		slice "Chrome" 6420
		slice "Safari" 1830 color="#d95926"
	}

The properties of L<Term::Fabulous::Widget::Chart/KDL PROPERTIES>;
C<hole>, C<start_angle>, C<sort>, C<slice_labels>, C<legend_values>,
C<center_text>, C<marker>, C<other>, C<other_label>, C<gap> (C<#true>
or C<#false>) and C<format> as the parameters; and one C<slice> node per
slice with the label and the value as its arguments and an optional
C<color> property. The slice nodes add the slices in their order, as
C<add_slice> does; C<data>, C<labels> and C<colors> are not layout
properties. More slices can be added from Perl after the layout is
built.

=head1 SUBCLASS INTERFACE

L<Term::Fabulous::Widget::DonutChart> and
L<Term::Fabulous::Widget::PolarAreaChart> are subclasses of PieChart
that override some of the methods below. A round chart of your own can
do the same. These methods come in addition to the ones of
L<Term::Fabulous::Widget::Chart/SUBCLASS INTERFACE>, which PieChart
already provides; C<$look> is the hash of colors described there.

=over

=item C<default_hole>, C<default_slice_labels>, C<default_legend_values>

The defaults of C<hole>, C<slice_labels> and C<legend_values>: 0,
C<percent> and C<percent>. A donut chart's C<default_hole> is 0.6; a
polar area chart's C<default_slice_labels> is C<none> and its
C<default_legend_values> is C<value>.

=item C<shown_slices($look)>

The slices as they are drawn: the slices with a value above 0, sorted
as C<sort> says, the small ones folded into one slice as C<other> and
C<other_label> say.
Each is a hash with C<label>, C<value>, C<share> (of the total, from 0
to 1) and the colors it is drawn in. C<legend_entries> and
C<draw_plot> call it.

=item C<slice_geometry( $look, @slices )>

Returns one C<[ $from, $to, $reach ]> per slice of C<shown_slices>:
the start and end angle in turns (0 to 1, before C<start_angle> is
added), and how far out the slice reaches (1 is the full radius). By
default each slice takes an angle in proportion to its share and
reaches the full radius; a polar area chart gives every slice the same
angle and lets the value decide its reach.

=item C<draw_background_grid( $surface, $x, $y, $width, $height, $circle, $look, \@slices )>

=item C<draw_foreground_grid( $surface, $x, $y, $width, $height, $circle, $look, \@slices )>

Called before and after the slices are drawn into the plot area at
C<$x>, C<$y> of the L<Term::Fabulous::Chart::Surface>. C<$circle> is
the hash of L<Term::Fabulous::Chart::Radial/circle_frame>, relative to
the plot area. Both draw nothing by default; a polar area chart draws
its rings behind the slices and their values in front of them.

=back

=head1 SEE ALSO

L<Term::Fabulous::Widget::DonutChart>, L<Term::Fabulous::Widget::PolarAreaChart>,
L<Term::Fabulous::Widget::Chart> (title, legend, colors, hover),
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Show shares as a pie or donut (PieChart, DonutChart)>,
the example programs F<examples/widgets/pie-chart.pl> and
F<examples/widgets/pie-chart-styles.pl>.

=cut
