package Term::Fabulous::Role::HasSeries;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Series;

role Term::Fabulous::Role::HasSeries {
	use Carp qw(croak);
	use Scalar::Util qw(weaken);
	use List::Util qw(uniq);
	use Term::Fabulous::Check qw(describe one_of);

	field @_series;
	field %_series_by_name;
	field $_next_slot = 0;
	field %_defaults;    # the series options given to the chart
	field $_point_check;    # what every series checks its new points with

	# The type a series has when it gives none.
	method default_series_type;

	# The series types the chart draws.
	method series_types;

	# The series options the chart takes for all of its series.
	method series_default_names;

	# Dies when the chart cannot show a series of a type in its current
	# state (a horizontal chart takes only bars); called before a series
	# is added or changes its type.
	method check_series_type;

	# Dies when the chart cannot show data points (a radar chart takes
	# only its labels as x); called with the parsed points before a
	# series stores them.
	method check_series_points;

	# Ends a hover on a series that is not among the names given; the
	# role calls it when series go or are hidden.
	method end_hover_unless_shown;

	# The chart's point check as a series calls it: with the series and
	# its new points. The series must not keep the chart alive.
	method _point_check () {
		return $_point_check //= do {
			weaken( my $chart = $self );
			sub ( $series, $points ) { $chart->check_series_points( $series->name, $points ) if defined $chart; return };
		};
	}

	method _check_type ($type) {
		my @types = $self->series_types;
		croak ref($self) . ": a " . ref($self) . " draws series of the types " . join( ', ', @types ) . ", not " . describe($type)
			unless defined $type && !ref $type && grep { $_ eq $type } @types;
		return $type;
	}

	# ---------------------------------------------------------------------
	# Chart-wide series options
	# ---------------------------------------------------------------------

	# Checked by the series code, on a series of a type that takes them.
	method _set_default ( $key, $value ) {
		my @known = $self->series_default_names;
		croak ref($self) . ": unknown series default '$key' (known: @known)" unless grep { $_ eq $key } @known;
		if ( !defined $value ) {
			delete $_defaults{$key};
		}
		elsif ( $key eq 'marker' ) {
			one_of( $self, marker => $value, uniq map { Term::Fabulous::Chart::Series->marker_names($_) } $self->series_types );
			$_defaults{$key} = $value;
		}
		else {
			my $type  = $key eq 'fill_opacity' || $key eq 'value_labels' ? 'area' : 'line';
			my $probe = Term::Fabulous::Chart::Series->new( owner => ref $self, name => 'chart', described_as => '', type => $type, slot => 0 );
			$probe->set_option( $key => $value );
			$_defaults{$key} = $probe->option($key);
		}
		$self->_limit($_) foreach @_series;
		$self->mark_changed;
		return;
	}

	method series_default ( $key, @new ) {
		my @known = $self->series_default_names;
		croak ref($self) . ": unknown series default '$key' (known: @known)" unless grep { $_ eq $key } @known;
		$self->_set_default( $key => $new[0] ) if @new;
		return $_defaults{$key};
	}

	# A series option: the series' own, else the chart's (when the series'
	# type can use it), else undef.
	method series_option ( $series, $key ) {
		my $own = $series->option($key);
		return $own if defined $own;
		my $default = $_defaults{$key};
		return undef unless defined $default;
		return undef if $key eq 'marker' && !grep { $_ eq $default } Term::Fabulous::Chart::Series->marker_names( $series->type );
		return $default;
	}

	# A series without a max_points of its own keeps the chart's.
	method _limit ($series) {
		my $limit = $_defaults{max_points} // return;
		$series->keep_last($limit) unless defined $series->option('max_points');
		return;
	}

	# ---------------------------------------------------------------------
	# Series
	# ---------------------------------------------------------------------

	method add_series (@specs) {
		croak ref($self) . ": add_series needs a hash reference or key-value pairs" if @specs != 1 && @specs % 2;
		my %spec = @specs == 1 && ref $specs[0] eq 'HASH' ? $specs[0]->%* : @specs;
		my $name = delete $spec{name} // $self->_free_series_name;
		croak ref($self) . ": a series named '$name' exists already" if $_series_by_name{$name};
		my $type = $self->_check_type( delete $spec{type} // $self->default_series_type );
		$self->check_series_type( $name, $type );
		my $series = Term::Fabulous::Chart::Series->new(
			owner        => ref $self,
			name         => $name,
			type         => $type,
			slot         => $_next_slot,
			check_points => $self->_point_check,
			%spec,
		);
		$_next_slot++;
		push @_series, $series;
		$_series_by_name{$name} = $series;
		$self->_limit($series);
		$self->mark_changed;
		return $self;
	}

	# The first of 'Series N' no series has, from N = the count + 1.
	method _free_series_name () {
		my $number = @_series + 1;
		$number++ while $_series_by_name{"Series $number"};
		return "Series $number";
	}

	method _series ($name) {
		return $_series_by_name{ $name // '' } // croak ref($self) . ": no series named " . describe($name);
	}

	method remove_series (@names) {
		my %gone = map { $self->_series($_)->name => 1 } @names;
		@_series = grep { !$gone{ $_->name } } @_series;
		delete @_series_by_name{ keys %gone };
		$self->_end_hidden_hover;
		$self->mark_changed;
		return $self;
	}

	method clear_series () {
		@_series         = ();
		%_series_by_name = ();
		$self->_end_hidden_hover;
		$self->mark_changed;
		return $self;
	}

	# A hover on a series the chart no longer shows ends.
	method _end_hidden_hover () {
		$self->end_hover_unless_shown( map { $_->name } $self->visible_series );
		return;
	}

	method series_names () {
		return map { $_->name } @_series;
	}

	method has_series ($name) {
		return $_series_by_name{ $name // '' } ? 1 : 0;
	}

	# The series objects, in order; for the chart's own drawing.
	method all_series () {
		return @_series;
	}

	method visible_series () {
		return grep { $_->is_visible } @_series;
	}

	# A description of a series: its name, type, color, options and data
	# as they were given.
	method series ($name) {
		my $series  = $self->_series($name);
		my %options = map { my $value = $series->option($_); defined $value ? ( $_ => $value ) : () } grep { $_ ne 'transform' } Term::Fabulous::Chart::Series->option_names;
		return {
			name => $series->name,
			type => $series->type,
			( defined $series->color ? ( color => sprintf '#%06x', $series->color ) : () ),
			%options,
			data => [ map { defined $_->[0] ? [ $_->@* ] : $_->[1] } $series->points->@* ],
		};
	}

	method set_series ( $name, %options ) {
		my $series = $self->_series($name);
		croak ref($self) . ": set_series cannot rename a series" if exists $options{name};
		my $type = exists $options{type} ? $self->_check_type( delete $options{type} ) : $series->type;
		$self->check_series_type( $name, $type );

		# Everything is checked on a probe first, so a bad option leaves
		# the series as it was.
		Term::Fabulous::Chart::Series->new( owner => ref $self, name => $name, type => $type, slot => $series->slot, check_points => $self->_point_check, %options );
		$series->set_type($type) if $type ne $series->type;
		foreach my $key ( sort keys %options ) {
			$key eq 'color' ? $series->set_color( $options{$key} ) : $key eq 'data' ? $series->set_data( $options{$key} ) : $series->set_option( $key => $options{$key} );
		}
		$self->_limit($series);
		$self->_end_hidden_hover;
		$self->mark_changed;
		return $self;
	}

	method set_data ( $name, $data ) {
		my $series = $self->_series($name);
		$series->set_data($data);
		$self->_limit($series);
		$self->mark_changed;
		return $self;
	}

	method add_points ( $name, @points ) {
		my $series = $self->_series($name);
		$series->add_points(@points);
		$self->_limit($series);
		$self->mark_changed;
		return $self;
	}

	method clear_data ($name) {
		$self->_series($name)->clear;
		$self->mark_changed;
		return $self;
	}

	# One new point for several series at once: the value of each series
	# named in %$values at $x (undef: the next index).
	method append ( $x, $values ) {
		croak ref($self) . ": append needs a hash reference of values by series name, got " . describe($values) unless ref $values eq 'HASH';
		my @series = map { $self->_series($_) } sort keys $values->%*;

		# Every value is parsed before any series changes, so a bad one
		# leaves all of them as they were.
		my @parsed = map {
			my $value = $values->{ $_->name };
			[ $_->parsed_points( defined $x ? [ $x, $value ] : $value ) ]
		} @series;
		foreach my $index ( 0 .. $#series ) {
			$series[$index]->push_parsed( $parsed[$index]->@* );
			$self->_limit( $series[$index] );
		}
		$self->mark_changed;
		return $self;
	}

	method show_series (@names) {
		$self->_series($_)->set_option( visible => 1 ) foreach @names;
		$self->mark_changed;
		return $self;
	}

	method hide_series (@names) {
		$self->_series($_)->set_option( visible => 0 ) foreach @names;
		$self->_end_hidden_hover;
		$self->mark_changed;
		return $self;
	}

	method is_series_visible ($name) {
		return $self->_series($name)->is_visible;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Role::HasSeries - Named data series of a chart

=head1 SYNOPSIS

	$chart->add_series( { name => 'web', data => [ 3, 5, 4 ], color => '#3987e5' } );
	$chart->add_points( web => 6, 7 );
	$chart->append( '2026-06-01 10:00', { web => 12, api => 4 } );
	$chart->set_series( web => ( line_style => 'dashed' ) );
	$chart->hide_series('api');
	$chart->remove_series('web');

=head1 DESCRIPTION

The series of L<Term::Fabulous::Widget::XYChart> and
L<Term::Fabulous::Widget::RadarChart>: adding, changing and removing them
and their data. Every series has a unique name; methods find series by it
and die for names the chart does not have. Every change shows in the next
frame. The methods that change series return the chart, so calls can
be chained.

Each series gets the next color of the chart's palette when it is added
and keeps it, also when series before it are removed. Options the chart
takes for all of its series (C<curve>, C<marker>, ...) apply to every
series that has none of its own.

=head1 METHODS

=head2 add_series

	$chart->add_series( { name => $name, type => $type, data => \@data, color => $color, %options } );
	$chart->add_series( name => $name, data => \@data );

Adds a series at the end; see L<Term::Fabulous::Widget::XYChart/SERIES>
for its keys. A series without a name is called C<Series N>, with the
number after the count of series (C<Series 1>, C<Series 2>, ...), or the
next one no series has yet when that name is taken. Dies for a name the chart has already, a type the chart cannot
draw, invalid options or data, and data the chart cannot show (a radar
chart: a value for a label it does not have); nothing is added then.

=head2 remove_series, clear_series

	$chart->remove_series( 'web', 'api' );
	$chart->clear_series;

Remove the named series, or all of them. An unknown name dies before any
series is removed. The remaining series keep their colors. When the
mouse pointer is on a series that goes, the hover ends as if the pointer
had moved off it (see L<Term::Fabulous::Widget::Chart/Hover and emphasis>).

=head2 series_names, has_series

The names of all series in order; whether a name is one of them.

=head2 series

	my $description = $chart->series('web');
	# { name => 'web', type => 'line', color => '#3987e5', curve => 'monotone', data => [ ... ] }

A new hash describing a series: name, type, color (as C<#rrggbb>, when it
has one of its own), the options it has set itself except C<transform>,
and the data: y values for points without x, C<[ x, y ]> pairs for the
others (points given as hashes come back as pairs).

=head2 set_series

	$chart->set_series( web => ( type => 'area', fill_opacity => 0.5, color => undef ) );

Changes the type, the color, the data or options of a series; C<undef>
removes an option (the chart's applies again) or the color (the palette's
applies again). The name cannot change. Everything is checked first: an
invalid value dies and leaves the series as it was. A new type drops a
C<marker> of the series that the new type cannot draw with.

=head2 set_data, add_points, clear_data

	$chart->set_data( web => [ 1, 2, 3 ] );
	$chart->add_points( web => [ $time, 4.2 ], [ $time + 60, 3.9 ] );
	$chart->clear_data('web');

Replace, extend or empty the data of a series. With C<max_points> (the
series' own or the chart's), the oldest points are dropped. Invalid data,
or data the chart cannot show, dies and changes nothing.

=head2 append

	$chart->append( $x, { web => 12, api => 4 } );
	$chart->append( undef, { web => 12 } );    # the next index

Adds one point to each series named in the hash, all at the same x (with
C<undef>: each at its next position): the way to feed several series from
one measurement. Every value is checked before any series changes: an
unknown name or an invalid value for one series dies and adds no point
to any series, so the series stay in step.

=head2 show_series, hide_series, is_series_visible

A hidden series is not drawn, has no legend entry and does not count for
the axes; its data is kept. Hiding the series the mouse pointer is on
ends the hover, as removing it does; so does C<< set_series( $name,
visible =E<gt> 0 ) >>.

=head2 series_default

	my $curve = $chart->series_default('curve');
	$chart->series_default( curve => 'monotone' );

Reads or sets an option the chart gives all its series; C<undef> removes
it. Dies for a name the chart does not take as a series option, and for
an invalid value. The charts also have an accessor for each
(C<< $chart->curve('monotone') >>).

=head2 series_option

	my $curve = $chart->series_option( $series, 'curve' );

The option a series object is drawn with: its own, or the chart's.

=head2 all_series, visible_series

The L<Term::Fabulous::Chart::Series> objects, all or the visible ones;
for the chart's own drawing code.

=head1 REQUIRED METHODS

C<default_series_type>, C<series_types> (the types the chart draws),
C<series_default_names> (the options it takes for all its series),
C<< end_hover_unless_shown(@names) >> (which
L<Term::Fabulous::Widget::Chart> provides: the role calls it with the
names of the visible series after series go or are hidden),
C<< check_series_type( $name, $type ) >>, which dies when the chart cannot
show a series of that type in its current state (the role calls it
before a series is added or changes its type), and
C<< check_series_points( $name, $points ) >>, which dies when the chart
cannot show the points (C<[ $x, $y ]> pairs, as
L<Term::Fabulous::Chart::Series/points, count> holds them); the role has every
series call it with its new points before they are stored, so bad data
dies at once and leaves the series as it was.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::RadarChart>,
L<Term::Fabulous::Chart::Series>, L<Term::Fabulous::Manual::Charts/Series and data>,
L<Term::Fabulous::Cookbook::ChartTechniques/A live chart that follows new data (append, max_points, span)>.

=cut
