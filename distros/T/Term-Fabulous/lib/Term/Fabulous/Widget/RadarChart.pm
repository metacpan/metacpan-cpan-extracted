package Term::Fabulous::Widget::RadarChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Role::HasSeries;
use Term::Fabulous::Widget::Chart;

class Term::Fabulous::Widget::RadarChart
	:isa(Term::Fabulous::Widget::Chart)
	:does(Term::Fabulous::Role::HasSeries)
	:strict(params)
{
	use Carp qw(croak);
	use List::Util ();
	use POSIX qw(floor ceil);
	use Scalar::Util qw(looks_like_number);
	use Term::Fabulous::Check qw(boolean one_of);
	use Term::Fabulous::Chart::Format qw(check_number_format format_value);
	use Term::Fabulous::Chart::Marker;
	use Term::Fabulous::Chart::Radial qw(CELL_ASPECT TAU circle_frame point_at);
	use Term::Fabulous::Chart::Raster;
	use Term::Fabulous::Chart::Scale::Linear;
	use Term::Fabulous::Chart::Surface;
	use Term::Fabulous::Chart::Transform qw(apply_transforms);
	use Term::Fabulous::Widget::Table::Value qw(number_of);

	use constant {
		FILL_OPACITY => 0.25,
		DOT_POINT    => 'dot',
		SQUARE_POINT => 'square',
		POINT        => "\x{2022}",
		LEGEND_POINT => "\x{25CF}",
	};

	my @GRID     = qw(polygon circle none);
	my @DEFAULTS = qw(marker line_style points point fill_opacity transform);

	field $initial_series :param(series) = [];
	field $labels         :param         = [];
	field $min            :param         = undef;
	field $max            :param         = undef;
	field $ticks          :param         = undef;
	field $grid           :param         = 'polygon';
	field $format         :param         = undef;
	field $start_angle    :param         = 0;

	ADJUST :params ( :$marker = undef, :$line_style = undef, :$points = undef, :$point = undef, :$fill_opacity = undef, :$transform = undef ) {
		my %given = ( marker => $marker, line_style => $line_style, points => $points, point => $point, fill_opacity => $fill_opacity, transform => $transform );
		$self->_set_default( $_ => $given{$_} ) foreach grep { defined $given{$_} } @DEFAULTS;
		$labels = $self->_checked_labels($labels);
		$self->_check_ends( $self->_checked_end( min => $min ), $self->_checked_end( max => $max ) );
		$self->_fail( 'ticks', 'a positive integer or undef', $ticks ) if defined $ticks && ( ref $ticks || $ticks !~ /\A[1-9][0-9]*\z/ );
		one_of( $self, grid => $grid, @GRID );
		$format = check_number_format( ref $self, 'format', $format );
		$self->_fail( 'start_angle', 'a number of degrees', $start_angle ) unless defined number_of($start_angle);
		croak ref($self) . ": series must be an array reference of series hashes" unless ref $initial_series eq 'ARRAY';
		$self->add_series($_) foreach @$initial_series;
		$initial_series = undef;
	}

	method default_series_type ()             { return 'area' }
	method series_types ()                    { return qw(area line) }
	method series_default_names ()            { return @DEFAULTS }
	method check_series_type ( $name, $type ) { return }

	# A point given by label needs an axis of that name.
	method check_series_points ( $name, $points ) {
		$self->_check_axes_of( $labels, $name, $points );
		return;
	}

	method _check_axes_of ( $axes, $name, $points ) {
		my %is_axis = map { $_ => 1 } @$axes;
		foreach my $point (@$points) {
			my $x = $point->[0] // next;
			croak ref($self) . ": series '$name' has a value for '$x', which is not one of the labels" unless $is_axis{$x};
		}
		return;
	}

	method _checked_labels ($value) {
		croak ref($self) . ": labels must be an array reference of strings" unless ref $value eq 'ARRAY' && !grep { !defined || ref } @$value;
		return [ map { "$_" } @$value ];
	}

	method _checked_end ( $name, $value ) {
		$self->_fail( $name, 'a number or undef', $value ) if defined $value && !defined number_of($value);
		return $value;
	}

	# Dies unless a min and a max, when both are given, leave room between
	# them.
	method _check_ends ( $low, $high ) {
		return unless defined $low && defined $high;
		croak ref($self) . ": min ($low) must be less than max ($high)" unless $low < $high;
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

	method min (@new) {
		return $min unless @new;
		$self->_check_ends( $self->_checked_end( min => $new[0] ), $max );
		return $self->_set( \$min, $new[0] );
	}

	method max (@new) {
		return $max unless @new;
		$self->_check_ends( $min, $self->_checked_end( max => $new[0] ) );
		return $self->_set( \$max, $new[0] );
	}

	method grid         (@new) { return @new ? $self->_set( \$grid, one_of( $self, grid => $new[0], @GRID ) ) : $grid }
	method format       (@new) { return @new ? $self->_set( \$format, check_number_format( ref $self, 'format', $new[0] ) ) : $format }
	method marker       (@new) { return $self->series_default( marker       => @new ) }
	method line_style   (@new) { return $self->series_default( line_style   => @new ) }
	method points       (@new) { return $self->series_default( points       => @new ) }
	method point        (@new) { return $self->series_default( point        => @new ) }
	method fill_opacity (@new) { return $self->series_default( fill_opacity => @new ) }

	# New labels must still give every value its axis.
	method labels (@new) {
		return [@$labels] unless @new;
		my $axes = $self->_checked_labels( $new[0] );
		$self->_check_axes_of( $axes, $_->name, $_->points ) foreach $self->all_series;
		return [ $self->_set( \$labels, $axes )->@* ];
	}

	method ticks (@new) {
		return $ticks unless @new;
		$self->_fail( 'ticks', 'a positive integer or undef', $new[0] ) if defined $new[0] && ( ref $new[0] || $new[0] !~ /\A[1-9][0-9]*\z/ );
		return $self->_set( \$ticks, $new[0] );
	}

	method start_angle (@new) {
		return $start_angle unless @new;
		$self->_fail( 'start_angle', 'a number of degrees', $new[0] ) unless defined number_of( $new[0] );
		return $self->_set( \$start_angle, $new[0] + 0 );
	}

	method transform (@new) {
		$self->_set_default( transform => $new[0] ) if @new;
		return;
	}

	# ---------------------------------------------------------------------
	# Data
	# ---------------------------------------------------------------------

	# The values of each visible series by axis: a number per label, in
	# the order of the labels ([ label, value ] points name their axis;
	# check_series_points saw to it that the label is one).
	method _prepared () {
		my %axis_of = map { $labels->[$_] => $_ } 0 .. $#$labels;
		my @prepared;
		foreach my $series ( $self->visible_series ) {
			my @values = (undef) x @$labels;
			my $index  = 0;
			foreach my $point ( $series->points->@* ) {
				my ( $x, $y ) = @$point;
				my $axis = defined $x ? $axis_of{$x} : $index;
				$values[$axis] = $y if $axis < @$labels;
				$index++;
			}
			if ( my $steps = $self->series_option( $series, 'transform' ) ) {
				( undef, my $ys ) = apply_transforms( $steps, [ 0 .. $#values ], \@values );
				@values = @$ys;
			}
			push @prepared, { series => $series, name => $series->name, values => \@values };
		}
		return @prepared;
	}

	# ---------------------------------------------------------------------
	# Drawing
	# ---------------------------------------------------------------------

	method default_legend_position () {
		return 'top';
	}

	method legend_entries ($look) {
		return map { { series => $_->name, label => $_->name, color => $_->color // $self->slot_color( $look, $_->slot ), symbol => $_->type eq 'line' ? 'line' : 'fill' } } $self->visible_series;
	}

	method draw_plot ( $surface, $x, $y, $width, $height, $look ) {
		my $count = @$labels;
		return if $count < 3;
		my @prepared = $self->_prepared;
		my $measure  = sub ($text) { Term::Fabulous::Chart::Surface->text_columns($text) };

		# Room for the axis labels around the circle: their width at the
		# sides, a row above and below.
		my $label_columns = List::Util::max( map { $measure->($_) } @$labels ) + 1;
		my $circle        = circle_frame( $label_columns, 1, $width - 2 * $label_columns, $height - 2 );
		return if $circle->{radius} < 2;
		my $radius = $circle->{radius};
		my $start  = $start_angle / 360;

		my @all   = grep { defined } map { $_->{values}->@* } @prepared;
		my $scale = Term::Fabulous::Chart::Scale::Linear->fit(
			extent  => @all ? [ List::Util::min(@all), List::Util::max(@all) ] : undef,
			cells   => List::Util::max( 2, floor( $radius / 2 ) + 1 ),
			zero    => 1,
			align   => 0,
			integer => !grep( { $_ != int } @all ) ? 1 : 0,
			format  => $format,
			( defined $min   ? ( min   => $min )   : () ),
			( defined $max   ? ( max   => $max )   : () ),
			( defined $ticks ? ( ticks => $ticks ) : () ),
		);
		my $distance_of = sub ($value) { List::Util::max( 0, $scale->position($value) ) * $radius };
		my $vertex      = sub ( $axis, $distance ) { [ point_at( $circle, $distance, $axis / $count, $start ) ] };

		# The web: rings at the ticks and a spoke to every axis.
		my $web = Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named('braille'), columns => $width, rows => $height );
		if ( $grid ne 'none' ) {
			foreach my $tick ( $scale->ticks ) {
				my $distance = $distance_of->( $tick->{value} );
				next unless $distance > 0;
				my @ring
					= $grid eq 'circle'
					? map { [ point_at( $circle, $distance, $_ / List::Util::max( 24, floor( TAU * $distance * 2 ) ), $start ) ] } 0 .. List::Util::max( 24, floor( TAU * $distance * 2 ) )
					: map { $vertex->( $_ % $count, $distance ) } 0 .. $count;
				_polyline( $web, \@ring, $look->{grid}, undef );
			}
			_polyline( $web, [ $vertex->( $_, 0 ), $vertex->( $_, $radius ) ], $look->{grid}, undef ) foreach 0 .. $count - 1;
		}

		# The series: translucent fills, the web over them (its dots keep a
		# fill's color as their background), the outlines on top.
		my @order = sort { $self->is_emphasized( $look, $a->{name} ) <=> $self->is_emphasized( $look, $b->{name} ) } @prepared;
		my %fills;
		my @fill_order;
		my $lines = Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named('braille'), columns => $width, rows => $height );
		my @points;
		foreach my $entry (@order) {
			my $series  = $entry->{series};
			my $color   = $self->shown_color( $look, $entry->{name}, $series->color // $self->slot_color( $look, $series->slot ) );
			my @targets = map { $self->register_target( series => $entry->{name}, index => $_, label => $labels->[$_], value => $entry->{values}[$_] ) } 0 .. $count - 1;
			my @corners = map { $vertex->( $_, $distance_of->( $entry->{values}[$_] // $scale->min ) ) } 0 .. $count - 1;

			# Between two corners the nearer one owns the fill and the
			# outline, so the pointer reports the nearest axis.
			my @midpoints = map { _midpoint( $corners[$_], $corners[ ( $_ + 1 ) % $count ] ) } 0 .. $count - 1;
			if ( $series->type eq 'area' ) {
				my $marker = $self->series_option( $series, 'marker' ) // 'quadrant';
				my $fill   = $fills{$marker} //= do {
					push @fill_order, $marker;
					Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named($marker), columns => $width, rows => $height );
				};
				my ( $sx, $sy ) = ( $fill->marker->columns, $fill->marker->rows );
				my $opacity = ( $self->series_option( $series, 'fill_opacity' ) // FILL_OPACITY ) * $series->color_opacity;
				my $center  = [ $circle->{center_x}, $circle->{center_y} ];
				foreach my $axis ( 0 .. $count - 1 ) {
					my @sector = ( $center, $midpoints[ ( $axis - 1 ) % $count ], $corners[$axis], $midpoints[$axis] );
					$fill->fill_polygon( [ map { [ $_->[0] * $sx, $_->[1] * $sy ] } @sector ], $color, $targets[$axis], $opacity, $look->{base} );
				}
			}
			$lines->start_pattern( $series->dash_pattern( $self->series_option( $series, 'line_style' ) // 'solid' ) );
			foreach my $axis ( 0 .. $count - 1 ) {
				my ( $from, $middle, $to ) = ( $corners[$axis], $midpoints[$axis], $corners[ ( $axis + 1 ) % $count ] );
				$lines->line( $from->[0] * 2,   $from->[1] * 4,   $middle->[0] * 2, $middle->[1] * 4, $color, $targets[$axis] );
				$lines->line( $middle->[0] * 2, $middle->[1] * 4, $to->[0] * 2,     $to->[1] * 4,     $color, $targets[ ( $axis + 1 ) % $count ] );
			}
			$lines->start_pattern(undef);
			if ( $self->series_option( $series, 'points' ) ) {
				my $glyph  = $self->series_option( $series, 'point' ) // POINT;
				my @valued = grep { defined $entry->{values}[$_] } 0 .. $count - 1;
				if ( $glyph eq DOT_POINT || $glyph eq SQUARE_POINT ) {
					_raster_point( $lines, $glyph, $corners[$_], $color, $targets[$_] ) foreach @valued;
				}
				else {
					push @points, map { [ floor( $corners[$_][0] ), floor( $corners[$_][1] ), $glyph, $color, $targets[$_] ] } @valued;
				}
			}
		}
		$surface->composite( $fills{$_}, 'fill',   $x, $y ) foreach @fill_order;
		$surface->composite( $web,       'stroke', $x, $y );
		$surface->composite( $lines,     'stroke', $x, $y );
		foreach my $point (@points) {
			my ( $column, $row, $glyph, $color, $owner ) = @$point;
			$surface->put( $x + $column, $y + $row, $glyph, $color );
			$surface->set_owner( $x + $column, $y + $row, 'stroke', $owner );
		}

		# The axis labels around the web, and the values of the rings along
		# the first spoke: right of it when it is upright, above it when it
		# lies flat; never over an axis label.
		my @taken;    # [ row, first column, last column ] of each axis label
		foreach my $axis ( 0 .. $count - 1 ) {
			my $text = $labels->[$axis];
			my ( $at_x, $at_y ) = point_at( $circle, $radius + 1, $axis / $count, $start );
			my $dx            = $at_x - $circle->{center_x};
			my $width_of_text = $measure->($text);
			my $column
				= abs($dx) < 1 ? floor( $at_x - $width_of_text / 2 + 0.5 )
				: $dx > 0      ? ceil($at_x)
				:                floor($at_x) - $width_of_text + 1;
			$column = List::Util::max( 0, $column );
			$surface->text( $x + $column, $y + floor($at_y), $text, $look->{text}, max => $width - $column );
			push @taken, [ floor($at_y), $column, $column + $width_of_text - 1 ];
		}
		my ( $end_x, $end_y ) = point_at( $circle, $radius, 0, $start );
		my $spoke_is_flat = abs( $end_x - $circle->{center_x} ) > abs( $end_y - $circle->{center_y} ) * CELL_ASPECT;

		# A ring label needs a free column around it; axis labels and the
		# ring labels placed before it take their cells.
		foreach my $tick ( reverse $scale->ticks ) {
			my $distance = $distance_of->( $tick->{value} );
			next unless $distance > 0;
			my ( $at_x, $at_y ) = point_at( $circle, $distance, 0, $start );
			my $width_of_text = $measure->( $tick->{label} );
			my ( $column, $row ) = $spoke_is_flat ? ( floor( $at_x - $width_of_text / 2 + 0.5 ), floor($at_y) - 1 ) : ( floor($at_x) + 1, floor($at_y) );
			next if $row < 0 || $column < 0;
			my $last = $column + $width_of_text - 1;
			next if grep { $_->[0] == $row && $column <= $_->[2] + 1 && $last >= $_->[1] - 1 } @taken;
			$surface->text( $x + $column, $y + $row, $tick->{label}, $look->{label}, max => $width - $column );
			push @taken, [ $row, $column, $last ];
		}
		return;
	}

	# A dot or square point drawn into a raster: the subpixel at the
	# corner, or the two by two around it.
	sub _raster_point ( $raster, $glyph, $corner, $color, $owner ) {
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		if ( $glyph eq DOT_POINT ) {
			$raster->set( floor( $corner->[0] * $sx ), floor( $corner->[1] * $sy ), $color, $owner );
			return;
		}
		my ( $left, $top ) = ( floor( $corner->[0] * $sx - 0.5 ), floor( $corner->[1] * $sy - 0.5 ) );
		$raster->set( $left + $_ % 2, $top + int( $_ / 2 ), $color, $owner ) foreach 0 .. 3;
		return;
	}

	sub _midpoint ( $from, $to ) {
		return [ ( $from->[0] + $to->[0] ) / 2, ( $from->[1] + $to->[1] ) / 2 ];
	}

	sub _polyline ( $raster, $points, $color, $owner ) {
		foreach my $index ( 1 .. $#$points ) {
			my ( $from, $to ) = @$points[ $index - 1, $index ];
			$raster->line( $from->[0] * 2, $from->[1] * 4, $to->[0] * 2, $to->[1] * 4, $color, $owner );
		}
		return;
	}

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			min          => 'scalar',
			max          => 'scalar',
			ticks        => 'scalar',
			grid         => 'scalar',
			format       => 'scalar',
			start_angle  => 'scalar',
			marker       => 'scalar',
			line_style   => 'scalar',
			points       => 'boolean',
			point        => 'scalar',
			fill_opacity => 'scalar',
			labels       => \&_parse_labels,
			series       => \&_parse_series,
		);
	}

	method apply_layout_settings :override (@settings) {
		my @ordered = map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ $_->[0] eq 'series' ? 1 : 0, $_ ] } @settings;
		return $self->SUPER::apply_layout_settings(@ordered);
	}

	method _parse_labels ($kid) {
		my @labels = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'labels' takes one or more labels" unless @labels && !$kid->props->@* && !$kid->children->@*;
		$self->labels( \@labels );
		return;
	}

	# series "Alice" type="line" color="#3987e5" { data 4 5 3 4 2 }
	# series "Bob" { point "Speed" 4; point "Power" 3 }
	method _parse_series ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'series' needs the series name as its one argument" unless @args == 1 && defined $args[0] && !ref $args[0];
		my %spec = ( name => "$args[0]", map { $_->[0] => $_->[1]->as_perl } $kid->props->@* );
		my @data;
		foreach my $child ( $kid->children->@* ) {
			my $name   = $child->name;
			my @values = map { $_->as_perl } $child->args->@*;
			croak ref($self) . ": a series node holds 'data' and 'point' nodes, got '$name'" unless $name eq 'data'  || $name eq 'point';
			croak ref($self) . ": '$name' in series '$args[0]' takes no properties or children" if $child->props->@* || $child->children->@*;
			if ( $name eq 'point' ) {
				croak ref($self) . ": 'point' in series '$args[0]' takes a label and a value" unless @values == 2 && defined $values[0] && !ref $values[0];
				push @data, [ "$values[0]", $values[1] ];
			}
			else {
				push @data, @values;
			}
		}
		$self->add_series( %spec, data => \@data );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::RadarChart - Several values per series on axes
around a center

=head1 SYNOPSIS

	use Term::Fabulous::Widget::RadarChart;

	my $chart = Term::Fabulous::Widget::RadarChart->new(
		title  => 'Laptop ratings',
		labels => [ 'Speed', 'Battery', 'Screen', 'Keyboard', 'Weight', 'Price' ],
		max    => 10,
		points => 1,
		series => [
			{ name => 'Model A', data => [ 9, 6, 8, 7, 5, 4 ] },
			{ name => 'Model B', data => [ 6, 9, 6, 8, 9, 7 ] },
			{ name => 'Average', type => 'line', line_style => 'dashed', data => [ [ Speed => 7 ], [ Price => 6 ] ] },
		],
	);

	$chart->set_data( 'Model A' => [ 9, 7, 8, 7, 6, 4 ] );
	$chart->grid('circle');

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-radar-chart.svg" alt="Two translucent polygons for two laptop models over a web of six axes labeled Speed, Battery, Screen, Keyboard, Weight and Price"></p>

=end html

F<examples/widgets/radar-chart.pl> draws this chart.

=head1 DESCRIPTION

A radar chart (a spider or web chart) compares profiles: each series
has one value per axis, the axes radiate from a center, and the values
of a series join into a polygon. One look shows where a profile is
strong and where it is weak, and how two profiles differ in shape.
It suits a handful of series over three to about eight axes whose values
share a scale (ratings, percentages).

The axes are the C<labels>, clockwise from 12 o'clock (C<start_angle>
turns them). Rings mark round values from the center (C<min>, 0 by
default) to the outer ring (C<max>, a round value above the data), as a
C<polygon> through the axes or a C<circle>, with a spoke from the
center to every axis label; the values of the rings are written along
the first axis. C<< grid =E<gt> 'none' >> leaves out the rings, the
spokes and the ring values. An C<area> series (the default type) is a
translucent polygon with its outline, a C<line> series only the outline;
C<points> marks the values. The web is drawn over the fills and under
the outlines, so it stays readable.

Hover emphasizes a series and reports the axis nearest to the pointer:
its label and the series' value there. The series methods are those of
L<Term::Fabulous::Role::HasSeries>; the title, legend (at the top by
default), colors and hover mechanics those of
L<Term::Fabulous::Widget::Chart>.

=head2 Data

	data => [ 9, 6, 8, 7, 5, 4 ]                                    # one value per label, in order
	data => [ [ Speed => 9 ], [ Screen => 8 ] ]                     # by label; the others are left out
	data => [ 9, undef, 8 ]                                         # a missing value

A series gives its values in the order of the labels, or as
C<[ label, value ]> pairs; a label that is not an axis dies when the data
is given (C<add_series>, C<set_data>, C<add_points>, ...), and the
series keeps the data it had. A missing value (C<undef>, or a label left
out) is drawn at the center. Values beyond the labels are ignored. A
series' C<transform> runs on its values in axis order.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::RadarChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>, and:

=over

=item C<labels>

An array reference of at least three strings: the axes. With fewer, no
plot is drawn. Default: none.

=item C<series>

An array reference of series hashes with C<name>, C<type> (C<area>, the
default, or C<line>), C<data>, C<color> and the options below. See
L<Term::Fabulous::Widget::XYChart/Series keys> for the common keys.

=item C<min>, C<max>

Numbers: the values at the center and at the outer ring; with both
given, C<min> must be less than C<max>. Default: C<undef>, from the data
(the center is 0 unless the data goes below). A C<min> not below the
C<max> dies when it is given, also through the accessors, and changes
nothing.

=item C<ticks>

A positive integer: about how many rings you want; the chart picks the
round step that comes closest. Default: C<undef>, which spaces the rings
about three rows apart, so a larger chart has more of them.

=item C<grid>

C<polygon> (the default): rings that run straight from axis to axis;
C<circle>: round rings; C<none>: no rings, spokes or ring values.

=item C<format>

How the ring values are written: C<si>, C<integer>, C<percent>, a
C<sprintf> format or a code reference; see
L<Term::Fabulous::Chart::Format>. Default: C<undef>, as many decimals
as the step between the rings needs.

=item C<start_angle>

Degrees clockwise from 12 o'clock for the first axis. Default: 0.

=item C<marker>, C<line_style>, C<points>, C<point>, C<fill_opacity>, C<transform>

Series options for every series without one of its own (a series hash
may set each of them too):

=over

=item C<marker>

The characters of the fill: C<quadrant> (the default), C<half>,
C<sextant> or C<braille>.

=item C<line_style>

The outline: C<solid> (the default), C<dashed> or C<dotted>.

=item C<points>, C<point>

C<points> true marks every value; C<point> is the mark: a single
character (a bullet, C<U+2022>, by default), or C<dot> (one Braille dot
at the corner) or C<square> (two by two Braille dots around it), drawn
with the outlines as in L<Term::Fabulous::Widget::XYChart/Points>.

=item C<fill_opacity>

0 to 1: how much of the fill color covers the background. Default: 0.25.

=item C<transform>

Steps that prepare the values; see
L<Term::Fabulous::Chart::Transform>.

=back

=back

=head1 METHODS

Every parameter except C<series> has an accessor of the same name
(the series methods are listed below): without an argument it returns
the value, with one it checks and sets it, and an invalid
value dies and changes nothing. C<labels> returns a copy, and dies
without changing anything for labels that would leave a value of a
series without its axis; C<transform> only sets, and returns nothing.

	$chart->labels( [ 'Speed', 'Battery', 'Screen', 'Keyboard', 'Weight', 'Price', 'Ports' ] );
	$chart->max(undef);         # from the data again
	$chart->fill_opacity(0.4);

The series are managed with the methods of
L<Term::Fabulous::Role::HasSeries> (C<add_series>, C<set_series>,
C<set_data>, C<add_points>, C<remove_series>, C<hide_series>, ...); the
chart also has C<hovered>, C<revision> and C<effective_background> from
L<Term::Fabulous::Widget::Chart>.

=head1 EVENTS

C<SeriesHover> (L<Term::Fabulous::Event::SeriesHover>) with the series,
the number of the nearest axis as the index, its label and the value
there.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::RadarChart as RadarChart

	RadarChart "ratings" {
		labels "Speed" "Battery" "Screen" "Keyboard" "Weight" "Price"
		max 10
		grid "circle"
		points #true
		series "Model A" { data 9 6 8 7 5 4 }
		series "Average" type="line" line_style="dashed" {
			point "Speed" 7
			point "Price" 6
		}
	}

The properties of L<Term::Fabulous::Widget::Chart/KDL PROPERTIES>;
C<min>, C<max>, C<ticks>, C<grid>, C<format>, C<start_angle>,
C<marker>, C<line_style>, C<points>, C<point> and C<fill_opacity> as
the parameters; C<labels> with the axes as its arguments; and one
C<series> node per series with its name as the argument, C<type>,
C<color> and the series options as properties, and C<data> nodes
(values in axis order) or C<point "label" value> nodes in its block.
The labels are applied before the series.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Chart> (title, legend, colors, hover),
L<Term::Fabulous::Role::HasSeries>, L<Term::Fabulous::Widget::PolarAreaChart>,
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Compare profiles on radar and polar area charts (RadarChart, PolarAreaChart)>,
the example program F<examples/widgets/radar-chart.pl>.

=cut
