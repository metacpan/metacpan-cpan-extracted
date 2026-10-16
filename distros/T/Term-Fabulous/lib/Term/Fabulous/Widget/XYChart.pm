package Term::Fabulous::Widget::XYChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Role::HasSeries;
use Term::Fabulous::Widget::Chart;

class Term::Fabulous::Widget::XYChart
	:isa(Term::Fabulous::Widget::Chart)
	:does(Term::Fabulous::Role::HasSeries)
	:abstract
{
	use Carp qw(croak);
	use Feature::Compat::Try;
	use List::Util qw(all any first max min sum0 uniq);
	use POSIX qw(ceil floor strftime);
	use Scalar::Util qw(blessed looks_like_number);
	use Term::Fabulous::Check qw(boolean describe glyph one_of);
	use Term::Fabulous::Chart::Curve qw(curve_points y_at check_curve);
	use Term::Fabulous::Chart::Format qw(number_formatter format_value format_values check_number_format check_time_format time_formatter);
	use Term::Fabulous::Chart::Marker;
	use Term::Fabulous::Chart::Palette qw(mix_rgb);
	use Term::Fabulous::Chart::Raster;
	use Term::Fabulous::Chart::Scale::Category;
	use Term::Fabulous::Chart::Scale::Linear;
	use Term::Fabulous::Chart::Scale::Log;
	use Term::Fabulous::Chart::Scale::Time;
	use Term::Fabulous::Chart::Series;
	use Term::Fabulous::Chart::Surface;
	use Term::Fabulous::Chart::Transform qw(parse_transforms apply_transforms);
	use Term::Fabulous::Widget::Table::Value qw(date_epoch number_of);

	use constant {
		DOT_POINT            => 'dot',
		SQUARE_POINT         => 'square',
		LINE_POINT           => "\x{2022}",    # bullet
		LEGEND_POINT         => "\x{25CF}",    # black circle
		AREA_FILL_OPACITY    => 0.6,
		STACKED_FILL_OPACITY => 0.8,
		TREND_PATTERN        => [ 4, 2 ],
	};

	my %GRID_GLYPHS = (
		solid  => [ "\x{2500}", "\x{2502}" ],
		dashed => [ "\x{254C}", "\x{254E}" ],
		dotted => [ "\x{2508}", "\x{250A}" ],
	);
	my @X_TYPES         = qw(auto linear log time category);
	my @Y_TYPES         = qw(linear log);
	my @AXIS_KEYS       = qw(type min max title format ticks step grid visible zero utc span base nice);
	my @SERIES_DEFAULTS = qw(marker curve tension line line_style points point fill_opacity transform max_points span_gaps value_labels);

	field $initial_series :param(series) = [];
	field $labels         :param         = undef;
	field $x_axis         :param         = {};
	field $y_axis         :param         = {};
	field $stacked        :param         = 0;
	field $horizontal     :param         = 0;
	field $bar_width      :param         = 0.7;

	field @_kdl_chart_steps;    # the transform steps a layout gave so far
	field %_ends;    # x_axis and y_axis => { min, max } as the scales take them

	method series_types ()         { return qw(line area bar scatter) }
	method series_default_names () { return @SERIES_DEFAULTS }

	ADJUST :params (
		:$marker       = undef, :$curve     = undef, :$tension    = undef, :$line      = undef, :$line_style   = undef, :$points = undef, :$point = undef,
		:$fill_opacity = undef, :$transform = undef, :$max_points = undef, :$span_gaps = undef, :$value_labels = undef
		)
	{
		my %given = (
			marker     => $marker,     curve      => $curve,      tension   => $tension,   line         => $line,
			line_style => $line_style, points     => $points,     point     => $point,     fill_opacity => $fill_opacity,
			transform  => $transform,  max_points => $max_points, span_gaps => $span_gaps, value_labels => $value_labels,
		);
		$self->_set_default( $_ => $given{$_} ) foreach grep { defined $given{$_} } @SERIES_DEFAULTS;
		$labels = $self->_checked_labels($labels) if defined $labels;
		( $x_axis, $_ends{x_axis} ) = $self->_checked_axis( x_axis => $x_axis );
		( $y_axis, $_ends{y_axis} ) = $self->_checked_axis( y_axis => $y_axis );
		$stacked    = $self->_checked_stacked($stacked);
		$horizontal = boolean( $self, horizontal => $horizontal );
		$bar_width  = $self->_checked_fraction( bar_width => $bar_width );
		croak ref($self) . ": series must be an array reference of series hashes, got " . describe($initial_series) unless ref $initial_series eq 'ARRAY';
		$self->add_series($_) foreach @$initial_series;
		$initial_series = undef;
	}

	# ---------------------------------------------------------------------
	# Checks
	# ---------------------------------------------------------------------

	method _checked_labels ($value) {
		croak ref($self) . ": labels must be an array reference of strings, got " . describe($value) unless ref $value eq 'ARRAY';
		foreach my $label (@$value) {
			croak ref($self) . ": every label must be a string, got " . describe($label) unless defined $label && !ref $label;
		}
		return [@$value];
	}

	method _checked_stacked ($value) {
		return 0 unless defined $value;
		croak ref($self) . ": stacked must be 0, 1 or 'percent', got " . describe($value) unless !ref $value && $value =~ /\A(?:0|1|percent|)\z/;
		return $value eq 'percent' ? 'percent' : $value ? 1 : 0;
	}

	method _checked_axis ( $which, $spec ) {
		my $owner = ref $self;
		croak "$owner: $which must be a hash reference, got " . describe($spec) unless ref $spec eq 'HASH';
		my %axis    = %$spec;
		my %allowed = map  { $_ => 1 } @AXIS_KEYS;
		my @unknown = grep { !$allowed{$_} } sort keys %axis;
		croak "$owner: $which does not take @unknown (known: @AXIS_KEYS)" if @unknown;
		$axis{type} //= $which eq 'x_axis' ? 'auto' : 'linear';
		one_of( $owner, "$which type", $axis{type}, $which eq 'x_axis' ? @X_TYPES : @Y_TYPES );

		foreach my $key (qw(visible utc nice)) {
			$axis{$key} = boolean( $self, "$which $key", $axis{$key} ) if exists $axis{$key};
		}
		$axis{zero} = boolean( $self, "$which zero", $axis{zero} ) if defined $axis{zero};
		if ( exists $axis{grid} ) {
			my $grid = $axis{grid};
			$axis{grid}
				= !defined $grid || ( !ref $grid && $grid =~ /\A(?:0|)\z/ ) ? 0
				: !ref $grid && $grid eq '1'                                ? 'solid'
				: !ref $grid && $GRID_GLYPHS{$grid}                         ? $grid
				:                                                             croak "$owner: the grid of $which must be 0, 1, solid, dashed or dotted, got " . describe($grid);
		}
		croak "$owner: the title of $which must be a string, got " . describe( $axis{title} ) if ref $axis{title};
		foreach my $key (qw(ticks)) {
			croak "$owner: the $key of $which must be a positive integer, got " . describe( $axis{$key} ) if defined $axis{$key} && ( ref $axis{$key} || $axis{$key} !~ /\A[1-9][0-9]*\z/ );
		}
		foreach my $key (qw(step span)) {
			croak "$owner: the $key of $which must be a positive number, got " . describe( $axis{$key} ) if defined $axis{$key} && !( defined number_of( $axis{$key} ) && $axis{$key} > 0 );
		}
		croak "$owner: the base of $which must be a number greater than 1, got " . describe( $axis{base} ) if defined $axis{base} && !( defined number_of( $axis{base} ) && $axis{base} > 1 );
		if ( $axis{type} eq 'time' ) {
			check_time_format( $owner, "the format of $which", $axis{format} );
		}
		elsif ( $axis{type} ne 'auto' ) {
			check_number_format( $owner, "the format of $which", $axis{format} );
		}
		elsif ( defined $axis{format} && !ref $axis{format} && $axis{format} !~ /%/ ) {
			check_number_format( $owner, "the format of $which", $axis{format} );
		}
		return ( \%axis, $self->_parsed_ends( $which, \%axis ) );
	}

	# The ends an axis is given, as the numbers its scale takes: numbers
	# on y, linear and log axes, epoch seconds on time axes, either on an
	# automatic x axis (whose kind the data decides later); a category
	# axis has no ends. Dies for an end its axis cannot have.
	method _parsed_ends ( $which, $axis ) {
		my ( $owner, $type ) = ( ref $self, $axis->{type} );
		my %given = map { defined $axis->{$_} ? ( $_ => $axis->{$_} ) : () } qw(min max);
		if ( $type eq 'category' ) {
			foreach my $end ( sort keys %given ) {
				croak "$owner: the $end of $which must be a value, got " . describe( $given{$end} ) if ref $given{$end} && !( blessed $given{$end} && $given{$end}->can('epoch') );
			}
			return {};
		}
		my ( $parse, $expected )
			= $type eq 'time' ? ( \&date_epoch, 'a date on a time axis' )
			: $type eq 'auto' ? ( \&date_epoch, 'a number or a date' )
			:                   ( \&number_of, 'a number' );
		my %ends;
		foreach my $end ( sort keys %given ) {
			$ends{$end} = $parse->( $given{$end} ) // croak "$owner: the $end of $which must be $expected, got " . describe( $given{$end} );
			croak "$owner: the $end of $which must be greater than 0 on a log axis, got " . describe( $given{$end} ) if $type eq 'log' && $ends{$end} <= 0;
		}
		croak "$owner: the min of $which (" . _end_text( $given{min} ) . ") must be less than its max (" . _end_text( $given{max} ) . ")"
			if defined $ends{min} && defined $ends{max} && $ends{min} >= $ends{max};
		return \%ends;
	}

	# An axis end as messages show it: as it was given.
	sub _end_text ($end) {
		return ref $end ? describe($end) : $end;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method labels (@new) {
		return defined $labels ? [@$labels] : undef unless @new;
		$labels = defined $new[0] ? $self->_checked_labels( $new[0] ) : undef;
		$self->mark_changed;
		return $self->labels;
	}

	method x_axis (@new) {
		return {%$x_axis} unless @new;
		( $x_axis, $_ends{x_axis} ) = $self->_checked_axis( x_axis => $new[0] // {} );
		$self->mark_changed;
		return {%$x_axis};
	}

	method y_axis (@new) {
		return {%$y_axis} unless @new;
		( $y_axis, $_ends{y_axis} ) = $self->_checked_axis( y_axis => $new[0] // {} );
		$self->mark_changed;
		return {%$y_axis};
	}

	method stacked (@new) {
		return $stacked unless @new;
		$stacked = $self->_checked_stacked( $new[0] );
		$self->mark_changed;
		return $stacked;
	}

	method horizontal (@new) {
		return $horizontal unless @new;
		my $before = $horizontal;
		$horizontal = boolean( $self, horizontal => $new[0] );
		try {
			$self->_check_horizontal;
		}
		catch ($error) {
			$horizontal = $before;
			die $error;
		}
		$self->mark_changed;
		return $horizontal;
	}

	method bar_width (@new) {
		return $bar_width unless @new;
		$bar_width = $self->_checked_fraction( bar_width => $new[0] );
		$self->mark_changed;
		return $bar_width;
	}

	method marker       (@new) { return $self->series_default( marker       => @new ) }
	method line         (@new) { return $self->series_default( line         => @new ) }
	method curve        (@new) { return $self->series_default( curve        => @new ) }
	method tension      (@new) { return $self->series_default( tension      => @new ) }
	method line_style   (@new) { return $self->series_default( line_style   => @new ) }
	method points       (@new) { return $self->series_default( points       => @new ) }
	method point        (@new) { return $self->series_default( point        => @new ) }
	method fill_opacity (@new) { return $self->series_default( fill_opacity => @new ) }
	method max_points   (@new) { return $self->series_default( max_points   => @new ) }
	method span_gaps    (@new) { return $self->series_default( span_gaps    => @new ) }
	method value_labels (@new) { return $self->series_default( value_labels => @new ) }

	method transform (@new) {
		$self->_set_default( transform => $new[0] ) if @new;
		return;
	}

	# ---------------------------------------------------------------------
	# Preparing the data of a frame
	# ---------------------------------------------------------------------

	# What the x values are: the axis type, or guessed from the data.
	method _x_kind () {
		my $type = $x_axis->{type};
		return $type unless $type eq 'auto';
		return 'category' if defined $labels;
		my @xs = grep { defined } map {
			map { $_->[0] }
				$_->points->@*
		} $self->all_series;
		if ( !@xs ) {
			return ( any { $_->type eq 'bar' } $self->all_series ) ? 'category' : 'linear';
		}
		return 'linear' if !grep { !defined number_of($_) } @xs;
		return 'time' if !grep   { !defined date_epoch($_) } @xs;
		return 'category';
	}

	# Turns an x value into a number for the axis kind; dies for values
	# the axis cannot show.
	method _x_number ( $kind, $x, $series_name, $categories ) {
		if ( $kind eq 'category' ) {
			my $label = blessed $x && $x->can('epoch') ? strftime( '%Y-%m-%d', localtime $x->epoch ) : "$x";
			return $categories->{index}{$label} //= do { push $categories->{labels}->@*, $label; $categories->{labels}->$#* };
		}
		if ( $kind eq 'time' ) {
			return date_epoch($x) // croak ref($self) . ": the x value " . describe($x) . " of series '$series_name' is not a date (the x axis is a time axis)";
		}
		return number_of($x) // croak ref($self) . ": the x value " . describe($x) . " of series '$series_name' is not a number (the x axis is $kind)";
	}

	# The series as the frame draws them: x as numbers, prepared,
	# stacked. See draw_plot.
	method prepare_series () {
		my $kind       = $self->_x_kind;
		my $categories = { labels => [ defined $labels ? @$labels : () ], index => {} };
		$categories->{index}{ $categories->{labels}[$_] } //= $_ foreach 0 .. $categories->{labels}->$#*;

		my @prepared;
		foreach my $series ( $self->visible_series ) {
			my ( @xs, @ys );
			my $index = 0;
			foreach my $point ( $series->points->@* ) {
				my ( $x, $y ) = @$point;
				if ( !defined $x ) {
					croak ref($self) . ": series '" . $series->name . "' needs x values for a time axis (give [ x, y ] points)" if $kind eq 'time';
					if ( $kind eq 'category' ) {
						push $categories->{labels}->@*, $index + 1 while $categories->{labels}->@* <= $index;
						$x = $index;
					}
					else {
						$x = $index;
					}
				}
				else {
					$x = $self->_x_number( $kind, $x, $series->name, $categories );
				}
				push @xs, $x;
				push @ys, $y;
				$index++;
			}
			my $type = $series->type;
			if ( $kind ne 'category' && ( $type eq 'line' || $type eq 'area' ) ) {
				my @order = sort { $xs[$a] <=> $xs[$b] } 0 .. $#xs;
				@xs = @xs[@order];
				@ys = @ys[@order];
			}
			my $steps = $self->series_option( $series, 'transform' );
			( my $xs, my $ys ) = $steps ? apply_transforms( $steps, \@xs, \@ys ) : ( \@xs, \@ys );
			my ( $from, $to ) = map { my $raw = $series->option($_); defined $raw ? $self->_x_number( $kind, $raw, $series->name, $categories ) : undef } qw(from to);
			push @prepared, { series => $series, name => $series->name, type => $type, xs => $xs, ys => $ys, from => $from, to => $to };
		}
		$self->stack_series( \@prepared );
		return ( $kind, $categories->{labels}, \@prepared );
	}

	# Gives every point of stacked series a base (y0) and a top (y1); the
	# points of other series lie between the baseline and their value.
	method stack_series ($prepared) {
		my %totals;
		my $group_of = sub ($entry) {
			my $stack = $entry->{series}->option('stack') // ( $stacked && ( $entry->{type} eq 'bar' || $entry->{type} eq 'area' ) ? '' : undef );
			return defined $stack ? $entry->{type} . "\0" . $stack : undef;
		};
		if ( $stacked eq 'percent' ) {
			foreach my $entry (@$prepared) {
				my $group = $group_of->($entry) // next;
				$totals{$group}{ $entry->{xs}[$_] } += abs( $entry->{ys}[$_] // 0 ) foreach 0 .. $entry->{xs}->$#*;
			}
		}
		my %running;
		foreach my $entry (@$prepared) {
			my $group = $group_of->($entry);
			$entry->{group} = $group;
			my ( @lows, @highs );
			foreach my $index ( 0 .. $entry->{xs}->$#* ) {
				my ( $x, $y ) = ( $entry->{xs}[$index], $entry->{ys}[$index] );
				if ( !defined $group || !defined $y ) {
					push @lows,  undef;
					push @highs, $y;
					next;
				}
				$y = $totals{$group}{$x} ? $y / $totals{$group}{$x} : 0 if $stacked eq 'percent';
				my $side = $y < 0 ? 'negative' : 'positive';
				my $base = $running{$group}{$side}{$x} // 0;
				push @lows,  $base;
				push @highs, $base + $y;
				$running{$group}{$side}{$x} = $base + $y;
			}
			( $entry->{lows}, $entry->{highs} ) = ( \@lows, \@highs );
		}
		return;
	}

	# ---------------------------------------------------------------------
	# Drawing
	# ---------------------------------------------------------------------

	method default_legend_position () {
		return 'top';
	}

	# A hook for charts that show less than all of the data in narrow
	# room: gets the room and what prepare_series returns, and returns it
	# (changed).
	method fit_prepared ( $width, $kind, $categories, $prepared ) {
		return ( $kind, $categories, $prepared );
	}

	# Horizontal charts show only bars.
	method check_series_type ( $name, $type ) {
		croak ref($self) . ": a horizontal chart shows only bar series, but '$name' is a $type series" if $horizontal && $type ne 'bar';
		return;
	}

	# Any point an axis can show later; what the axes cannot show is
	# found when the frame is prepared.
	method check_series_points ( $name, $points ) {
		return;
	}

	method _check_horizontal () {
		$self->check_series_type( $_->name, $_->type ) foreach $self->all_series;
		return;
	}

	method legend_entries ($look) {
		return map {
			my $series = $_;
			my $type   = $series->type;
			{
				series => $series->name,
				label  => $series->name,
				color  => $self->_series_color( $look, $series ),
				symbol => $type eq 'line'    ? 'line' : $type eq 'scatter' ? 'point' : 'fill',
				glyph  => $type eq 'scatter' ? $self->_legend_point($series) : undef,
			}
		} $self->visible_series;
	}

	method _series_color ( $look, $series ) {
		return $series->color // $self->slot_color( $look, $series->slot );
	}

	method _point_glyph ($series) {
		my $glyph = $self->series_option( $series, 'point' );
		return $glyph // ( $series->type eq 'scatter' ? SQUARE_POINT : LINE_POINT );
	}

	# The point in the legend: the glyph, or a circle for dots.
	method _legend_point ($series) {
		my $glyph = $self->_point_glyph($series);
		return $glyph eq DOT_POINT || $glyph eq SQUARE_POINT ? LEGEND_POINT : $glyph;
	}

	method _marker_of ( $series, $orientation ) {
		my $name = $self->series_option( $series, 'marker' ) // ( $series->type eq 'area' || $series->type eq 'bar' ? 'block' : 'braille' );
		$name = 'block-horizontal' if $name eq 'block' && $orientation eq 'horizontal';
		return $name;
	}

	# Returns the number of rows used from the top of the area: the ticks
	# may leave rows below the axis free. Nothing when no plot fits.
	method draw_plot ( $surface, $x, $y, $width, $height, $look ) {
		my ( $kind, $categories, $prepared ) = $self->fit_prepared( $width, $self->prepare_series );
		my $frame = $self->_frame( $kind, $categories, $prepared, $x, $y, $width, $height ) // return;
		$self->_draw_grid( $surface, $frame, $look );
		$self->_draw_series( $surface, $frame, $prepared, $look );
		$self->_draw_axes( $surface, $frame, $look );
		my $bottom_shown = $frame->{orientation} eq 'vertical' ? $frame->{index_shown} : $frame->{value_shown};
		return $frame->{top} - $y + $frame->{rows} + ( $bottom_shown ? 1 : 0 ) + $frame->{title_below};
	}

	# Whether the chart reserves room for something: an axis that is
	# visible (the default).
	sub _shown ( $axis, $key ) {
		return $axis->{$key} // 1;
	}

	# The extent of x values (with the half slot bars need on numeric
	# axes) and of y values (bases included) over the drawn series. With
	# a span on the x axis, x runs over the last span up to the newest
	# point, and only the points in it count for y. Values a logarithmic
	# axis cannot show (0 and below) do not count.
	method _extents ( $kind, $prepared ) {
		my ( @xs, @samples );    # a sample: [ x, y, the y it rises from or undef ]
		foreach my $entry (@$prepared) {
			foreach my $index ( 0 .. $entry->{xs}->$#* ) {
				my $y = $entry->{highs}[$index] // next;
				my $x = $entry->{xs}[$index];
				next if defined $entry->{from} && $x < $entry->{from};
				next if defined $entry->{to}   && $x > $entry->{to};
				push @xs,      $x, ( $entry->{edges} ? $entry->{edges}[$index]->@* : () );
				push @samples, [ $x, $y, $entry->{lows}[$index] ];
			}
		}
		@xs = grep { $_ > 0 } @xs if $kind eq 'log';
		my $x_extent = @xs ? [ min(@xs), max(@xs) ] : undef;
		if ( $kind ne 'category' && $x_extent && !grep { $_->{edges} } @$prepared ) {
			my $spacing = $self->_bar_spacing($prepared);
			$x_extent = [ $x_extent->[0] - $spacing / 2, $x_extent->[1] + $spacing / 2 ] if $spacing;
		}
		my $span = $x_axis->{span};
		if ( defined $span && $x_extent && $kind ne 'category' ) {
			$x_extent = [ $x_extent->[1] - $span, $x_extent->[1] ];
			@samples  = grep { $_->[0] >= $x_extent->[0] } @samples;
		}
		my @ys = map { ( $_->[1], $_->[2] // () ) } @samples;
		@ys = grep { $_ > 0 } @ys if $y_axis->{type} eq 'log';
		my $y_extent = @ys ? [ min(@ys), max(@ys) ] : undef;
		return ( $x_extent, $y_extent );
	}

	# The smallest distance between two x values of bars on a numeric
	# axis: the width of one bar slot. 0 without bars.
	method _bar_spacing ($prepared) {
		my @xs = sort { $a <=> $b } uniq map { $_->{xs}->@* } grep { $_->{type} eq 'bar' && !$_->{edges} } @$prepared;
		return 0 unless @xs;
		return 1 if @xs == 1;
		return min( map { $xs[$_] - $xs[ $_ - 1 ] } 1 .. $#xs );
	}

	method value_format () {
		return $stacked eq 'percent' && !defined $y_axis->{format} ? 'percent' : $y_axis->{format};
	}

	# Lays out the axes and the plot in the chart's area and fits the
	# scales: the frame every part is drawn in.
	method _frame ( $kind, $categories, $prepared, $left, $top, $width, $height ) {
		my ( $x_extent, $y_extent ) = $self->_extents( $kind, $prepared );
		my $bar_like = any { $_->{type} eq 'bar' || $_->{type} eq 'area' || defined $_->{group} } @$prepared;
		my $percent  = $stacked eq 'percent';
		my $measure  = sub ($label) { Term::Fabulous::Chart::Surface->text_columns($label) };

		# The y axis holds the values and the x axis the x values
		# (categories), also when horizontal bars turn them on their side.
		my ( $value_axis, $index_axis ) = ( $y_axis, $x_axis );
		my $value_shown = _shown( $value_axis, 'visible' );
		my $index_shown = _shown( $index_axis, 'visible' );

		my $fit_value = sub ( $cells, $orientation ) {
			my %common = ( cells => $cells, orientation => $orientation, measure => $measure, extent => $y_extent, format => $self->value_format );
			return Term::Fabulous::Chart::Scale::Log->fit( %common, $_ends{y_axis}->%*, map { defined $value_axis->{$_} ? ( $_ => $value_axis->{$_} ) : () } qw(base) )
				if $value_axis->{type} eq 'log';
			my $integer = $y_extent && !grep { defined && $_ != int } map { $_->{ys}->@* } @$prepared;
			return Term::Fabulous::Chart::Scale::Linear->fit(
				%common,
				align   => $orientation eq 'vertical' || ( exists $value_axis->{grid} ? $value_axis->{grid} : 1 ) ? 1 : 0,
				zero    => $value_axis->{zero} // $bar_like,
				integer => $integer && !$percent,
				( $percent ? ( min => 0, max => 1 ) : () ),
				$_ends{y_axis}->%*,
				map { defined $value_axis->{$_} ? ( $_ => $value_axis->{$_} ) : () } qw(ticks step nice),
			);
		};
		my $band      = $kind eq 'category' && ( any { $_->{type} eq 'bar' } @$prepared ) ? 1 : 0;
		my $fit_index = sub ( $cells, $orientation ) {
			my %common = ( cells => $cells, orientation => $orientation, measure => $measure, format => $index_axis->{format} );
			return Term::Fabulous::Chart::Scale::Category->fit( %common, labels => $categories, band => $band ) if $kind eq 'category';
			my %ends = $_ends{x_axis}->%*;
			return Term::Fabulous::Chart::Scale::Time->fit( %common, extent => $x_extent, utc => $index_axis->{utc}, %ends ) if $kind eq 'time';
			return Term::Fabulous::Chart::Scale::Log->fit( %common, extent => $x_extent, base => $index_axis->{base}, %ends ) if $kind eq 'log';
			return Term::Fabulous::Chart::Scale::Linear->fit(
				%common,
				align   => $index_axis->{grid} ? 1 : 0,
				integer => (
					!grep { $_ != int } map {
						$_->{xs}->@*,
							map { @$_ } ( $_->{edges} // [] )->@*
					} @$prepared
				) ? 1 : 0,
				extent => $x_extent,
				nice   => $index_axis->{nice} // ( ( grep { $_->{edges} } @$prepared ) ? 0 : 1 ),
				%ends,
				map { defined $index_axis->{$_} ? ( $_ => $index_axis->{$_} ) : () } qw(ticks step),
			);
		};

		my $frame            = { kind => $kind, band => $band, edges => ( grep { $_->{edges} } @$prepared ) ? 1 : 0 };
		my $title_rows_below = defined $x_axis->{title} && length $x_axis->{title} ? 1 : 0;
		my $title_row_above  = defined $y_axis->{title} && length $y_axis->{title} ? 1 : 0;

		if ( !$horizontal ) {
			my $plot_rows = $height - ( $index_shown ? 1 : 0 ) - $title_rows_below - $title_row_above;
			if ( $plot_rows < 2 ) {
				( $title_rows_below, $title_row_above ) = ( 0, 0 );
				$plot_rows   = $height - ( $index_shown && $height > 3 ? 1 : 0 );
				$index_shown = 0 if $plot_rows == $height;
			}
			return undef if $plot_rows < 1;

			# Bars with value labels keep a row free above the highest one.
			my $label_room = $plot_rows >= 6 && ( grep { $_->{type} eq 'bar' && $self->series_option( $_->{series}, 'value_labels' ) } @$prepared ) ? 1 : 0;
			$plot_rows -= $label_room;
			my $value_scale = $fit_value->( $plot_rows, 'vertical' );

			# Rows the ticks leave unused go below the axis, where they read
			# as a margin.
			$plot_rows = $value_scale->used;
			my $gutter = $value_shown ? max( map { $measure->( $_->{label} ) } $value_scale->ticks ) + 1 : 0;
			$gutter = 0 if $gutter > $width / 2;

			# The labels of the last x tick may stick out right of the plot.
			my $margin = 0;
			my $index_scale;
			foreach my $attempt ( 1, 2 ) {
				my $plot_columns = $width - $gutter - $margin;
				return undef if $plot_columns < 2;
				$index_scale = $fit_index->( $plot_columns, 'horizontal' );
				last if $band || $frame->{edges} || !$index_shown;
				my @ticks  = $index_scale->ticks;
				my $last   = $ticks[-1] // last;
				my $wanted = max( 0, ceil( $measure->( $last->{label} ) / 2 - ( 1 - $last->{position} ) * ( $index_scale->used - 1 ) - ( $plot_columns - $index_scale->used ) - 1e-9 ) );
				last if $wanted <= $margin;
				$margin = $wanted;
			}
			%$frame = (
				%$frame,
				orientation => 'vertical',
				left        => $left + $gutter,
				top         => $top + $title_row_above + $label_room,
				label_room  => $label_room,
				columns     => $width - $gutter - $margin,
				rows        => $plot_rows,
				value_scale => $value_scale,
				index_scale => $index_scale,
				gutter      => $gutter,
				area_left   => $left,
				area_width  => $width,
				value_shown => $value_shown,
				index_shown => $index_shown,
				title_above => $title_row_above,
				title_below => $title_rows_below,
			);
			return $frame;
		}

		# Horizontal bars: categories down the left, values along the bottom.
		my $plot_rows = $height - ( $value_shown ? 1 : 0 ) - $title_rows_below - $title_row_above;
		if ( $plot_rows < 2 ) {
			( $title_rows_below, $title_row_above ) = ( 0, 0 );
			$plot_rows   = $height - ( $value_shown && $height > 3 ? 1 : 0 );
			$value_shown = 0 if $plot_rows == $height;
		}
		return undef if $plot_rows < 1;
		my $index_scale  = $fit_index->( $plot_rows, 'vertical' );
		my $gutter       = $index_shown ? min( max( 0, map { $measure->( $_->{label} ) } $index_scale->ticks ) + 1, int( $width / 3 ) ) : 0;
		my $plot_columns = $width - $gutter;
		return undef if $plot_columns < 2;
		my $value_scale = $fit_value->( $plot_columns, 'horizontal' );
		my @ticks       = $value_scale->ticks;
		my $margin      = @ticks ? max( 0, ceil( $measure->( $ticks[-1]{label} ) / 2 ) - ( $plot_columns - $value_scale->used ) ) : 0;

		if ( $margin && $plot_columns - $margin >= 2 ) {
			$value_scale = $fit_value->( $plot_columns - $margin, 'horizontal' );
		}
		else {
			$margin = 0;
		}
		%$frame = (
			%$frame,
			orientation => 'horizontal',
			left        => $left + $gutter,
			top         => $top + $title_row_above,
			columns     => $value_scale->used,
			rows        => $plot_rows,
			value_scale => $value_scale,
			index_scale => $index_scale,
			gutter      => $gutter,
			area_left   => $left,
			area_width  => $width,
			value_shown => $value_shown,
			index_shown => $index_shown,
			title_above => $title_row_above,
			title_below => $title_rows_below,
		);
		return $frame;
	}

	# Positions in cells inside the plot, continuous: the value axis puts
	# its ends on the centers of its first and last cell, so labels and
	# grid lines meet; categories take slots; histograms fill edge to edge.
	method _value_position ( $frame, $value ) {
		my $scale = $frame->{value_scale};
		my $t     = $scale->position($value) // return undef;
		if ( $self->value_axis_edges ) {
			return $frame->{orientation} eq 'vertical' ? ( 1 - $t ) * $frame->{rows} : $t * $frame->{columns};
		}
		if ( $frame->{orientation} eq 'vertical' ) {
			return ( $frame->{rows} - $scale->used ) + ( 1 - $t ) * ( $scale->used - 1 ) + 0.5;
		}
		return $t * ( $scale->used - 1 ) + 0.5;
	}

	# Whether the value axis runs from edge to edge of the plot instead of
	# from the center of its first cell to the center of its last, where
	# grid lines and labels meet the ticks. Charts without an axis (a
	# sparkline) use the whole height.
	method value_axis_edges () {
		return 0;
	}

	# Whether the baseline is drawn in the axis color.
	method draws_baseline () {
		return 1;
	}

	method _index_position ( $frame, $value ) {
		my $scale = $frame->{index_scale};
		my $t     = $scale->position($value) // return undef;
		my $cells = $frame->{orientation} eq 'vertical' ? $frame->{columns} : $frame->{rows};
		return $t * $cells if $frame->{band} || $frame->{edges};
		return $t * ( $scale->used - 1 ) + 0.5;
	}

	# The baseline bars and areas grow from: 0, or the end of the value
	# axis nearest to it.
	method _baseline ($frame) {
		my $scale = $frame->{value_scale};
		return $scale->min if $scale->kind eq 'log';
		return $scale->min > 0 ? $scale->min : $scale->max < 0 ? $scale->max : 0;
	}

	method _draw_grid ( $surface, $frame, $look ) {
		my ( $left, $top, $columns, $rows ) = @$frame{qw(left top columns rows)};
		my $vertical   = $frame->{orientation} eq 'vertical';
		my $value_grid = exists $y_axis->{grid} ? $y_axis->{grid} : 'solid';
		my $index_grid = exists $x_axis->{grid} ? $x_axis->{grid} : 0;

		# Value grid lines: rows in a vertical chart, columns in a horizontal one.
		if ($value_grid) {
			my $glyph = $GRID_GLYPHS{$value_grid}[ $vertical ? 0 : 1 ];
			foreach my $tick ( $frame->{value_scale}->ticks ) {
				my $at = floor( $self->_value_position( $frame, $tick->{value} ) // next );
				if ($vertical) {
					next if $at < 0 || $at >= $rows;
					$surface->put( $left + $_, $top + $at, $glyph, $look->{grid} ) foreach 0 .. $columns - 1;
				}
				else {
					next if $at < 0 || $at >= $columns;
					$surface->put( $left + $at, $top + $_, $glyph, $look->{grid} ) foreach 0 .. $rows - 1;
				}
			}
		}
		if ( $index_grid && !$frame->{band} ) {
			my $glyph = $GRID_GLYPHS{$index_grid}[ $vertical ? 1 : 0 ];
			my $cross = $value_grid eq 'solid' && $index_grid eq 'solid' ? "\x{253C}" : undef;
			foreach my $tick ( $frame->{index_scale}->ticks ) {
				my $at = floor( $self->_index_position( $frame, $tick->{value} ) // next );
				foreach my $along ( 0 .. ( $vertical ? $rows : $columns ) - 1 ) {
					my ( $x, $y ) = $vertical ? ( $left + $at, $top + $along ) : ( $left + $along, $top + $at );
					next unless $at >= 0 && $at < ( $vertical ? $columns : $rows );
					my $crossing = defined $cross && defined $surface->glyph_at( $x, $y ) && $surface->glyph_at( $x, $y ) eq $GRID_GLYPHS{solid}[ $vertical ? 0 : 1 ];
					$surface->put( $x, $y, $crossing ? $cross : $glyph, $look->{grid} );
				}
			}
		}

		# The baseline, in the axis color: where bars and areas grow from.
		return unless $self->draws_baseline;
		my $base = floor( $self->_value_position( $frame, $self->_baseline($frame) ) // return );
		$base = $vertical ? List::Util::min( $base, $rows - 1 ) : List::Util::min( $base, $columns - 1 );
		if ($vertical) {
			$surface->put( $left + $_, $top + $base, "\x{2500}", $look->{axis} ) foreach 0 .. $columns - 1;
		}
		else {
			$surface->put( $left + $base, $top + $_, "\x{2502}", $look->{axis} ) foreach 0 .. $rows - 1;
		}
		return;
	}

	# Every series, layer by layer: fills (areas, then bars) below lines,
	# lines below points. The emphasized series is drawn last in its layer
	# unless it is part of a stack.
	method _draw_series ( $surface, $frame, $prepared, $look ) {
		my @order = sort { $self->_draws_last( $look, $a ) <=> $self->_draws_last( $look, $b ) } @$prepared;
		my %rasters;    # marker name => raster, in order of first use
		my @raster_order;
		my $raster = sub ( $name, $layer ) {
			my $key = "$layer\0$name";
			return $rasters{$key} //= do {
				push @raster_order, $key;
				Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named($name), columns => $frame->{columns}, rows => $frame->{rows} );
			};
		};
		my @box_lines;    # drawn in cells, over the rasters
		my @glyph_points;    # [ column, row, glyph, color, owner ], over everything

		# Each point is a target the pointer can find.
		foreach my $entry (@order) {
			$entry->{targets} = [ map { $self->_point_target( $frame, $entry, $_ ) } 0 .. $entry->{xs}->$#* ];
			$entry->{color}   = $self->shown_color( $look, $entry->{name}, $self->_series_color( $look, $entry->{series} ) );
		}

		foreach my $entry ( grep { $_->{type} eq 'area' } @order ) {
			$self->_draw_area_fill( $raster->( $self->_marker_of( $entry->{series}, 'vertical' ), 'fill' ), $frame, $entry, $look );
		}
		my @bars = grep { $_->{type} eq 'bar' } @order;
		$self->_draw_bars( $raster, $frame, \@bars, $look ) if @bars;
		foreach my $entry ( grep { $_->{type} eq 'line' || ( $_->{type} eq 'area' && $self->_has_line($_) ) } @order ) {
			my $marker = $entry->{type} eq 'area' ? 'braille' : $self->_marker_of( $entry->{series}, 'vertical' );
			if ( $marker eq 'box' ) {
				push @box_lines, $entry;
			}
			else {
				$self->_draw_line( $raster->( $marker, 'stroke' ), $frame, $entry );
			}
			push @glyph_points, $self->_draw_points( $raster->( 'braille', 'stroke' ), $frame, $entry ) if $self->series_option( $entry->{series}, 'points' );
		}
		foreach my $entry ( grep { $_->{type} eq 'scatter' } @order ) {
			push @glyph_points, $self->_draw_points( $raster->( $self->_marker_of( $entry->{series}, 'vertical' ), 'stroke' ), $frame, $entry );
		}
		foreach my $entry ( grep { $self->series_option( $_->{series}, 'trend' ) } @order ) {
			$self->_draw_trend( $raster->( 'braille', 'stroke' ), $frame, $entry );
		}

		foreach my $key (@raster_order) {
			my ( $layer, $name ) = split /\0/, $key;
			$surface->composite( $rasters{$key}, $layer, $frame->{left}, $frame->{top} );
		}
		$self->_draw_box_line( $surface, $frame, $_ ) foreach @box_lines;
		foreach my $point (@glyph_points) {
			my ( $x, $y, $glyph, $color, $owner ) = @$point;
			$surface->put( $frame->{left} + $x, $frame->{top} + $y, $glyph, $color );
			$surface->set_owner( $frame->{left} + $x, $frame->{top} + $y, 'stroke', $owner );
		}
		$self->_draw_value_labels( $surface, $frame, \@bars, $look ) if grep { $self->series_option( $_->{series}, 'value_labels' ) } @bars;
		return;
	}

	# An area has no line along its top unless asked to: block fills show
	# the edge to an eighth of a cell, while a Braille line on top takes
	# over the cells it passes and so places the edge only to half a cell.
	method _has_line ($entry) {
		return $self->series_option( $entry->{series}, 'line' ) // 0;
	}

	method _draws_last ( $look, $entry ) {
		return $self->is_emphasized( $look, $entry->{name} ) && !defined $entry->{group} ? 1 : 0;
	}

	method _point_target ( $frame, $entry, $index ) {
		my $x     = $entry->{xs}[$index];
		my $scale = $frame->{index_scale};
		my $label
			= $entry->{labels}           ? $entry->{labels}[$index]
			: $scale->kind eq 'category' ? ( $scale->label_at($x) // $x )
			: $scale->kind eq 'time'     ? strftime( $x_axis->{format} && !ref $x_axis->{format} ? $x_axis->{format} : '%Y-%m-%d %H:%M', $x_axis->{utc} ? gmtime $x : localtime $x )
			:                              format_value($x);
		return $self->register_target( series => $entry->{name}, index => $index, label => $label, value => $entry->{ys}[$index], x => $x );
	}

	# The runs of drawable points of a series, as [ x, y, target ] in plot
	# cells: gaps (undef, or values a log axis cannot show) end a run
	# unless the series spans them. A run is { points => [...], sorted =>
	# whether x never falls }; the points of a sorted run are found by
	# halving it (line and area series are sorted unless on a category
	# axis).
	method _runs ( $frame, $entry, $values ) {
		my $span = $self->series_option( $entry->{series}, 'span_gaps' );
		my ( @runs, @run );
		foreach my $index ( 0 .. $entry->{xs}->$#* ) {
			my $value = $values->[$index];
			my $x     = $self->_index_position( $frame, $entry->{xs}[$index] );
			my $y     = defined $value ? $self->_value_position( $frame, $value ) : undef;
			if ( !defined $x || !defined $y ) {
				next if $span;
				push @runs, _run(@run) if @run;
				@run = ();
				next;
			}
			push @run, [ $x, $y, $entry->{targets}[$index] ];
		}
		push @runs, _run(@run) if @run;
		return @runs;
	}

	# A run of points, and whether it is sorted by x.
	sub _run (@points) {
		my $sorted = all { $points[ $_ - 1 ][0] <= $points[$_][0] } 1 .. $#points;
		return { points => \@points, sorted => $sorted ? 1 : 0 };
	}

	# How many of the first $count points pass $test, which a point passes
	# only when every point before it does.
	sub _leading ( $points, $count, $test ) {
		my ( $low, $high ) = ( 0, $count );
		while ( $low < $high ) {
			my $middle = int( ( $low + $high ) / 2 );
			$test->( $points->[$middle] ) ? ( $low = $middle + 1 ) : ( $high = $middle );
		}
		return $low;
	}

	# The polyline of a run along the series' curve, cut to from .. to.
	# Of a sorted run, only the segments that reach into the plot (or the
	# cell around it) are made, so a long history beside the plot costs
	# nothing; the shape there is the shape of the whole curve. With
	# whole, every segment is made: a dashed line counts the steps before
	# the plot for its dashes.
	method _run_polyline ( $frame, $entry, $run, $step, %options ) {
		my $points   = $run->{points};
		my $curve    = $self->series_option( $entry->{series}, 'curve' ) // 'linear';
		my @between  = $run->{sorted} && !$options{whole} ? ( between => [ _points_around( $points, -1, $frame->{columns} + 1 ) ] ) : ();
		my $polyline = curve_points( $points, $curve, step => $step, tension => $self->series_option( $entry->{series}, 'tension' ) // 0, @between );
		my ( $from, $to ) = map { defined $entry->{$_} ? $self->_index_position( $frame, $entry->{$_} ) : undef } qw(from to);
		return $polyline unless defined $from || defined $to;
		return _clip_polyline( $polyline, $from, $to );
	}

	# The first and last index of the points of a sorted run whose
	# segments reach into $left .. $right: from the last point left of it
	# to the first point right of it.
	sub _points_around ( $points, $left, $right ) {
		my $before_left = _leading( $points, scalar @$points, sub ($point) { $point->[0] < $left } );
		my $up_to_right = _leading( $points, scalar @$points, sub ($point) { $point->[0] <= $right } );
		return ( max( 0, $before_left - 1 ), min( $#$points, $up_to_right ) );
	}

	# The part of a polyline between two x positions, with the ends
	# interpolated, so a series starts and ends exactly there.
	sub _clip_polyline ( $polyline, $from, $to ) {
		my @kept;
		$from //= $polyline->[0][0];
		$to   //= $polyline->[-1][0];
		return [] if $to < $polyline->[0][0] || $from > $polyline->[-1][0];
		push @kept, [ $from, y_at( $polyline, $from ) ] if $from > $polyline->[0][0];
		push @kept, grep { $_->[0] >= $from && $_->[0] <= $to } @$polyline;
		push @kept, [ $to, y_at( $polyline, $to ) ] if $to < $polyline->[-1][0];
		return \@kept;
	}

	# The target of the point of a run nearest to x; of points as near,
	# the first. A sorted run is searched by halving it: the nearest point
	# is the first one at or right of x, or among those just left of it.
	sub _nearest_target ( $run, $x ) {
		my $points = $run->{points};
		return _nearest_target_by_scan( $points, $x ) unless $run->{sorted};
		my $right = _leading( $points, scalar @$points, sub ($point) { $point->[0] < $x } );
		return $points->[0][2] if $right == 0;
		my $left_distance = abs( $points->[ $right - 1 ][0] - $x );
		return $points->[$right][2] if $right < @$points && abs( $points->[$right][0] - $x ) < $left_distance;
		my $first_as_near = _leading( $points, $right, sub ($point) { abs( $point->[0] - $x ) > $left_distance } );
		return $points->[$first_as_near][2];
	}

	sub _nearest_target_by_scan ( $points, $x ) {
		my ( $best, $distance );
		foreach my $point (@$points) {
			my $away = abs( $point->[0] - $x );
			( $best, $distance ) = ( $point->[2], $away ) if !defined $distance || $away < $distance;
		}
		return $best;
	}

	method _draw_line ( $raster, $frame, $entry ) {
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		my $series  = $entry->{series};
		my $pattern = $series->dash_pattern( $self->series_option( $series, 'line_style' ) // 'solid' );
		$raster->start_pattern($pattern);
		foreach my $run ( $self->_runs( $frame, $entry, $entry->{highs} ) ) {
			my $polyline = $self->_run_polyline( $frame, $entry, $run, 1 / $sx, whole => defined $pattern );
			next unless @$polyline;
			if ( @$polyline == 1 ) {
				$raster->set( floor( $polyline->[0][0] * $sx ), floor( $polyline->[0][1] * $sy ), $entry->{color}, $run->{points}[0][2] );
				next;
			}
			foreach my $index ( 1 .. $#$polyline ) {
				my ( $from, $to ) = @$polyline[ $index - 1, $index ];
				my $owner = _nearest_target( $run, ( $from->[0] + $to->[0] ) / 2 );
				$raster->line( $from->[0] * $sx, $from->[1] * $sy, $to->[0] * $sx, $to->[1] * $sy, $entry->{color}, $owner );
			}
		}
		$raster->start_pattern(undef);
		return;
	}

	method _draw_area_fill ( $raster, $frame, $entry, $look ) {
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		my $opacity = ( $self->series_option( $entry->{series}, 'fill_opacity' ) // ( defined $entry->{group} ? STACKED_FILL_OPACITY : AREA_FILL_OPACITY ) ) * $entry->{series}->color_opacity;
		my $base_y  = $self->_value_position( $frame, $self->_baseline($frame) );
		my @lows    = $self->_runs( $frame, $entry, $entry->{lows} );
		foreach my $run ( $self->_runs( $frame, $entry, $entry->{highs} ) ) {
			my $top = $self->_run_polyline( $frame, $entry, $run, 1 / $sx );
			next if @$top < 2;
			my ( $run_start, $run_end ) = ( $run->{points}[0][0], $run->{points}[-1][0] );
			my $low    = first { $_->{points}[0][0] <= $run_start && $_->{points}[-1][0] >= $run_end } @lows;
			my $bottom = defined $entry->{group} && $low ? $self->_run_polyline( $frame, $entry, $low, 1 / $sx ) : undef;
			foreach my $column ( max( 0, floor( $top->[0][0] * $sx ) ) .. min( $raster->width - 1, ceil( $top->[-1][0] * $sx ) ) ) {
				my $center = ( $column + 0.5 ) / $sx;
				my $high_y = y_at( $top, $center ) // next;
				my $low_y  = $bottom ? y_at( $bottom, $center ) // $base_y : $base_y;
				$raster->fill_column( $column, $high_y * $sy, $low_y * $sy, $entry->{color}, _nearest_target( $run, $center ), $opacity, $look->{base} );
			}
		}
		return;
	}

	# Bars: in slots of categories (side by side for several series,
	# one on the other for a stack), around their x on a numeric axis,
	# or from edge to edge (histograms).
	method _draw_bars ( $raster_for, $frame, $bars, $look ) {
		my $vertical = $frame->{orientation} eq 'vertical';

		# The slots in series order, whatever order the bars are drawn in.
		my @columns   = uniq map { $_->{group} // "\0" . $_->{name} } sort { $a->{series}->slot <=> $b->{series}->slot } @$bars;
		my %column_of = map { $columns[$_] => $_ } 0 .. $#columns;
		my $length    = $vertical ? $frame->{columns} : $frame->{rows};
		my $slot
			= $frame->{band}  ? $frame->{index_scale}->slot_cells
			: $frame->{edges} ? undef
			: do {
			my $spacing = $self->_bar_spacing($bars);
			my $first   = $self->_index_position( $frame, 0 ) // 0;
			abs( ( $self->_index_position( $frame, $spacing ) // $first ) - $first ) || 1;
			};
		my $base = $self->_baseline($frame);

		$frame->{bar_columns} = scalar @columns;
		foreach my $entry (@$bars) {
			my $marker = $self->_marker_of( $entry->{series}, $vertical ? 'vertical' : 'horizontal' );
			my $raster = $raster_for->( $marker, 'fill' );
			my ( $along, $across ) = $vertical ? ( $raster->marker->columns, $raster->marker->rows ) : ( $raster->marker->rows, $raster->marker->columns );
			$frame->{bar_resolution} //= $along;
			my $opacity = ( $self->series_option( $entry->{series}, 'fill_opacity' ) // $self->default_bar_opacity($bars) ) * $entry->{series}->color_opacity;
			foreach my $index ( 0 .. $entry->{xs}->$#* ) {
				my $high = $entry->{highs}[$index] // next;
				my $low  = $entry->{lows}[$index]  // $base;
				my ( $start, $end );
				if ( $entry->{edges} ) {
					( $start, $end ) = map { $self->_index_position( $frame, $_ ) } $entry->{edges}[$index]->@*;
					$end -= $self->_bin_gap( $end - $start );
				}
				else {
					my $center = $self->_index_position( $frame, $entry->{xs}[$index] ) // next;
					( $start, $end ) = _bar_span( $center, $slot, $bar_width, scalar @columns, $column_of{ $entry->{group} // "\0" . $entry->{name} }, $along );
				}
				( $start, $end ) = map { floor( $_ * $along + 0.5 ) / $along } $start, $end;
				$end = $start + 1 / $along if $end <= $start;
				my ( $from, $to ) = map { $self->_value_position( $frame, $_ ) } $low, $high;
				next unless defined $from && defined $to;
				my $owner = $entry->{targets}[$index];
				if ($vertical) {
					$raster->fill_rect( $start * $along, $from * $across, $end * $along, $to * $across, $entry->{color}, $owner, $opacity, $look->{base} );
				}
				else {
					$raster->fill_rect( $from * $across, $start * $along, $to * $across, $end * $along, $entry->{color}, $owner, $opacity, $look->{base} );
				}
				$entry->{bar_ends}[$index] = [ ( $start + $end ) / 2, $to ];
			}
		}
		return;
	}

	# Bars are opaque; a histogram overrides this for overlapping bins.
	method default_bar_opacity ($bars) {
		return 1;
	}

	# The gap at the right of a histogram bin: one cell between wide bins.
	method _bin_gap ($width) {
		return $width >= 4 ? 1 : 0;
	}

	# The [start, end) of bar $column of $columns in the slot around
	# $center; the bars of a slot take $width of it together. Every bar
	# is a whole number of subpixels ($resolution per cell) wide, and the
	# bars of a slot are equally wide.
	sub _bar_span ( $center, $slot, $width, $columns, $column, $resolution ) {
		my ( $first, $each ) = _bar_group( $center, $slot, $width, $columns, $resolution );
		my $start = $first + $column * $each;
		return ( $start, $start + $each );
	}

	# Where the bars of a slot start, and how wide each is.
	sub _bar_group ( $center, $slot, $width, $columns, $resolution ) {
		my $each  = max( 1, floor( $slot * $width * $resolution / $columns ) ) / $resolution;
		my $first = floor( ( $center - $each * $columns / 2 ) * $resolution + 0.5 ) / $resolution;
		return ( $first, $each );
	}

	# The cell a label of the category at $center goes in, across the
	# bars: the middle of the bar group (its upper middle row, when the
	# group is an even number of cells high).
	method _category_cell ( $frame, $center ) {
		return floor($center) unless $frame->{band} && $frame->{bar_columns};
		my ( $first, $each ) = _bar_group( $center, $frame->{index_scale}->slot_cells, $bar_width, $frame->{bar_columns}, $frame->{bar_resolution} );
		return ceil( $first + $each * $frame->{bar_columns} / 2 ) - 1;
	}

	# Draws the points of a series: dots into the raster; returns the
	# glyph points, which are drawn over the cells later.
	method _draw_points ( $raster, $frame, $entry ) {
		my $glyph = $self->_point_glyph( $entry->{series} );
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		my @points;
		foreach my $run ( $self->_runs( $frame, $entry, $entry->{highs} ) ) {
			foreach my $point ( $run->{points}->@* ) {
				my ( $x, $y, $owner ) = @$point;
				next if defined $entry->{from} && $x < $self->_index_position( $frame, $entry->{from} );
				next if defined $entry->{to}   && $x > $self->_index_position( $frame, $entry->{to} );
				if ( $glyph eq DOT_POINT ) {
					$raster->set( floor( $x * $sx ), floor( $y * $sy ), $entry->{color}, $owner );
					next;
				}
				if ( $glyph eq SQUARE_POINT ) {
					my ( $left, $top ) = ( floor( $x * $sx - 0.5 ), floor( $y * $sy - 0.5 ) );
					$raster->set( $left + $_ % 2, $top + int( $_ / 2 ), $entry->{color}, $owner ) foreach 0 .. 3;
					next;
				}
				my ( $column, $row ) = ( floor($x), floor($y) );
				next if $column < 0 || $row < 0 || $column >= $frame->{columns} || $row >= $frame->{rows};
				push @points, [ $column, $row, $glyph, $entry->{color}, $owner ];
			}
		}
		return @points;
	}

	# The least-squares line through the points, dashed, from the first
	# to the last x.
	method _draw_trend ( $raster, $frame, $entry ) {
		my @known = grep { defined $entry->{highs}[$_] } 0 .. $entry->{xs}->$#*;
		return if @known < 2;
		my ( $xs,    $ys )   = apply_transforms( parse_transforms( ref $self, 'trend', 'regression' ), [ @{ $entry->{xs} }[@known] ], [ @{ $entry->{highs} }[@known] ] );
		my ( $first, $last ) = ( sort { $xs->[$a] <=> $xs->[$b] } 0 .. $#$xs )[ 0, -1 ];
		my @ends = map { [ $self->_index_position( $frame, $xs->[$_] ), $self->_value_position( $frame, $ys->[$_] ) ] } $first, $last;
		return if grep { !defined $_->[0] || !defined $_->[1] } @ends;
		my ( $sx, $sy ) = ( $raster->marker->columns, $raster->marker->rows );
		$raster->start_pattern(TREND_PATTERN);
		$raster->line( $ends[0][0] * $sx, $ends[0][1] * $sy, $ends[1][0] * $sx, $ends[1][1] * $sy, $entry->{color}, $entry->{targets}[ $known[0] ] );
		$raster->start_pattern(undef);
		return;
	}

	# A line of box drawing characters, one row per column (as the
	# asciichart program draws them), in the columns of the plot only: it
	# is drawn into the cells, where nothing clips it.
	method _draw_box_line ( $surface, $frame, $entry ) {
		my ( $left, $top ) = @$frame{qw(left top)};
		foreach my $run ( $self->_runs( $frame, $entry, $entry->{highs} ) ) {
			my $polyline = $self->_run_polyline( $frame, $entry, $run, 1 );
			next unless @$polyline;
			my $previous;
			foreach my $column ( max( 0, floor( $polyline->[0][0] ) ) .. min( $frame->{columns} - 1, floor( $polyline->[-1][0] ) ) ) {
				my $y     = y_at( $polyline, $column + 0.5 ) // y_at( $polyline, $polyline->[0][0] ) // next;
				my $row   = min( $frame->{rows} - 1, max( 0, floor($y) ) );
				my $owner = _nearest_target( $run, $column + 0.5 );
				my @cells;
				if ( !defined $previous || $previous == $row ) {
					@cells = ( [ $row, "\x{2500}" ] );
				}
				elsif ( $row < $previous ) {
					@cells = ( [ $previous, "\x{256F}" ], ( map { [ $_, "\x{2502}" ] } $row + 1 .. $previous - 1 ), [ $row, "\x{256D}" ] );
				}
				else {
					@cells = ( [ $previous, "\x{256E}" ], ( map { [ $_, "\x{2502}" ] } $previous + 1 .. $row - 1 ), [ $row, "\x{2570}" ] );
				}
				foreach my $cell (@cells) {
					$surface->put( $left + $column, $top + $cell->[0], $cell->[1], $entry->{color} );
					$surface->set_owner( $left + $column, $top + $cell->[0], 'stroke', $owner );
				}
				$previous = $row;
			}
		}
		return;
	}

	# The value of each bar (the total of a stack) beyond its end, where
	# there is room.
	method _draw_value_labels ( $surface, $frame, $bars, $look ) {
		my $vertical = $frame->{orientation} eq 'vertical';
		my %stack_end;    # the outermost end of each stack, by category
		foreach my $entry ( grep { $self->series_option( $_->{series}, 'value_labels' ) } @$bars ) {
			foreach my $index ( 0 .. $entry->{xs}->$#* ) {
				my $end = $entry->{bar_ends}[$index] // next;
				my $key
					= defined $entry->{group}
					? join( "\0", $entry->{group}, $entry->{xs}[$index], $entry->{highs}[$index] < ( $entry->{lows}[$index] // 0 ) ? '-' : '+' )
					: join( "\0", $entry->{name}, $index );
				my $value = defined $entry->{group} ? $entry->{highs}[$index] : $entry->{ys}[$index];
				my $known = $stack_end{$key};
				$stack_end{$key} = [ @$end, $value, $entry->{highs}[$index] >= ( $entry->{lows}[$index] // $self->_baseline($frame) ) ] if !$known || abs($value) >= abs( $known->[2] );
			}
		}
		my $format = $self->value_format;
		my @ends   = sort { $a->[0] <=> $b->[0] } values %stack_end;
		my @texts  = format_values( [ map { $_->[2] } @ends ], $format && $format ne 'auto' ? $format : undef );

		# A label that would touch one drawn before it in its row is left out.
		my %taken;    # row => [ [ from, to ] ... ]
		my $place = sub ( $row, $column, $width ) {
			return 0 if grep { $column <= $_->[1] && $column + $width - 1 >= $_->[0] } @{ $taken{$row} // [] };
			push @{ $taken{$row} }, [ $column - 1, $column + $width ];
			return 1;
		};
		foreach my $end (@ends) {
			my ( $middle, $tip, $value, $positive ) = @$end;
			my $text  = shift @texts;
			my $width = Term::Fabulous::Chart::Surface->text_columns($text);
			if ($vertical) {

				# Above the bar's top cell (below the end of a negative bar),
				# in the row the frame keeps free above the plot too.
				my $row = $positive ? floor($tip) - 1 : ceil($tip);
				next if $row < -( $frame->{label_room} // 0 ) || $row >= $frame->{rows};
				my $column = floor( $middle - $width / 2 + 0.5 );
				next if $column < 0 || $column + $width > $frame->{columns} || !$place->( $row, $column, $width );
				$surface->text( $frame->{left} + $column, $frame->{top} + $row, $text, $look->{text} );
			}
			else {
				my $row    = ceil($middle) - 1;
				my $column = $positive ? ceil($tip) + 1 : floor($tip) - $width;
				next if $column < 0 || $column + $width > $frame->{columns} || !$place->( $row, $column, $width );
				$surface->text( $frame->{left} + $column, $frame->{top} + $row, $text, $look->{text} );
			}
		}
		return;
	}

	# Tick labels, tick marks and axis titles.
	method _draw_axes ( $surface, $frame, $look ) {
		my ( $left, $top, $columns, $rows ) = @$frame{qw(left top columns rows)};
		my $vertical = $frame->{orientation} eq 'vertical';
		my $measure  = sub ($label) { Term::Fabulous::Chart::Surface->text_columns($label) };

		# The axis along the left: values (vertical) or categories (horizontal).
		my ( $left_scale, $bottom_scale ) = $vertical ? @$frame{qw(value_scale index_scale)} : @$frame{qw(index_scale value_scale)};
		my ( $left_shown, $bottom_shown ) = $vertical ? @$frame{qw(value_shown index_shown)} : @$frame{qw(index_shown value_shown)};
		if ( $left_shown && $frame->{gutter} ) {
			my $width = $frame->{gutter} - 1;
			my $last_row;
			foreach my $tick ( $left_scale->ticks ) {
				my $position = $vertical ? $self->_value_position( $frame, $tick->{value} ) : $self->_index_position( $frame, $tick->{value} );
				my $row      = $vertical ? floor( $position // next )                       : $self->_category_cell( $frame, $position // next );
				next if $row < 0 || $row >= $rows || ( defined $last_row && $row == $last_row );
				my $text_width = min( $measure->( $tick->{label} ), $width );
				$surface->text( $frame->{area_left} + $width - $text_width, $top + $row, $tick->{label}, $look->{label}, max => $width );
				$last_row = $row;
			}
		}

		# The axis along the bottom, below the plot.
		my $label_row = $top + $rows;
		if ($bottom_shown) {
			my $slot      = $bottom_scale->can('slot_cells') && $frame->{band} ? $bottom_scale->slot_cells : undef;
			my $free_from = $frame->{area_left};
			foreach my $tick ( $bottom_scale->ticks ) {
				my $position = $vertical ? $self->_index_position( $frame, $tick->{value} ) : $self->_value_position( $frame, $tick->{value} );
				next unless defined $position;
				my $label = $tick->{label};
				my $room  = defined $slot ? max( 1, floor($slot) - 1 ) : undef;
				my $width = min( $measure->($label), $room // $measure->($label) );
				my $start = $left + floor( $position - $width / 2 + ( defined $slot ? 0.5 : 0 ) );
				$start = max( $start, $frame->{area_left} );
				$start = min( $start, $frame->{area_left} + $frame->{area_width} - $width );
				next if $start < $free_from;
				$surface->text( $start, $label_row, $label, $look->{label}, max => $width );
				$free_from = $start + $width + 1;

				# A tick mark on the baseline below a point of a numeric axis.
				if ( $vertical && !$frame->{band} ) {
					my ( $mark_x, $mark_y ) = ( $left + floor($position), $top + $rows - 1 );
					my $glyph = $surface->glyph_at( $mark_x, $mark_y );
					$surface->put( $mark_x, $mark_y, "\x{252C}", $look->{axis} ) if defined $glyph && $glyph eq "\x{2500}" && $surface->fg_at( $mark_x, $mark_y ) == $look->{axis};
				}
			}
			$label_row++;
		}

		# Titles: the x axis title centered below, the y axis title above
		# the values.
		if ( $frame->{title_below} ) {
			my $title = $x_axis->{title};
			my $width = $measure->($title);
			$surface->text( $left + max( 0, int( ( $columns - $width ) / 2 ) ), $label_row, $title, $look->{label}, max => $frame->{area_width} );
		}

		# The y title sits right above the highest tick, also when the ticks
		# leave rows free at the top.
		if ( $frame->{title_above} ) {
			my $free = $vertical ? $rows - $frame->{value_scale}->used - ( $frame->{label_room} // 0 ) : 0;
			$surface->text( $frame->{area_left}, $top - 1 + $free, $y_axis->{title}, $look->{label}, max => $frame->{area_width} );
		}
		return;
	}

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			stacked      => 'scalar',
			horizontal   => 'boolean',
			bar_width    => 'scalar',
			marker       => 'scalar',
			curve        => 'scalar',
			tension      => 'scalar',
			line_style   => 'scalar',
			line         => 'boolean',
			points       => 'boolean',
			point        => 'scalar',
			fill_opacity => 'scalar',
			max_points   => 'scalar',
			span_gaps    => 'boolean',
			value_labels => 'boolean',
			labels       => \&_parse_labels,
			x_axis       => \&_parse_axis,
			y_axis       => \&_parse_axis,
			transform    => \&_parse_chart_transform,
			series       => \&_parse_series,
		);
	}

	# Axes and labels before the series, so the series' x values are read
	# the way the axis says.
	method apply_layout_settings :override (@settings) {
		my %rank    = ( labels => 0, x_axis => 0, y_axis => 0, transform => 1, series => 2 );
		my @ordered = map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ $rank{ $_->[0] } // 1, $_ ] } @settings;
		return $self->SUPER::apply_layout_settings(@ordered);
	}

	method _parse_labels ($kid) {
		my @labels = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'labels' takes one or more labels" unless @labels && !$kid->props->@* && !$kid->children->@*;
		$self->labels( [ map { "$_" } @labels ] );
		return;
	}

	method _parse_axis ($kid) {
		my $name  = $kid->name;
		my $props = $self->kdl_properties( $kid, @AXIS_KEYS );
		$self->$name( { %{ $self->$name }, %$props } );
		return;
	}

	# transform "cumulative"; transform "moving_average" 5 "center"
	sub _kdl_transform_step ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		return @args > 1 ? [@args] : $args[0];
	}

	# Every transform node adds a step to the chart's transform.
	method _parse_chart_transform ($kid) {
		croak ref($self) . ": layout property 'transform' takes a step name and its arguments" unless $kid->args->@* && !$kid->props->@* && !$kid->children->@*;
		push @_kdl_chart_steps, _kdl_transform_step($kid);
		$self->_set_default( transform => [@_kdl_chart_steps] );
		return;
	}

	# series "name" type="area" color="#3987e5" curve="monotone" {
	#     data 3 5 2 8
	#     point "2026-06-01" 5
	#     transform "moving_average" 3
	# }
	method _parse_series ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'series' needs the series name as its one argument" unless @args == 1 && defined $args[0] && !ref $args[0];
		my %spec = ( name => "$args[0]", map { $_->[0] => $_->[1]->as_perl } $kid->props->@* );
		my ( @data, @steps );
		foreach my $child ( $kid->children->@* ) {
			my $name   = $child->name;
			my @values = map { $_->as_perl } $child->args->@*;
			croak ref($self) . ": a series node holds 'data', 'point' and 'transform' nodes, got '$name'" unless $name eq 'data' || $name eq 'point' || $name eq 'transform';
			croak ref($self) . ": '$name' in series '$args[0]' takes no properties or children" if $child->props->@* || $child->children->@*;
			if ( $name eq 'data' ) {
				push @data, @values;
			}
			elsif ( $name eq 'point' ) {
				croak ref($self) . ": 'point' in series '$args[0]' takes an x and a y value" unless @values == 2;
				push @data, [@values];
			}
			else {
				croak ref($self) . ": 'transform' in series '$args[0]' takes a step name and its arguments" unless @values;
				push @steps, _kdl_transform_step($child);
			}
		}
		$self->add_series( %spec, data => \@data, ( @steps ? ( transform => \@steps ) : () ) );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::XYChart - The common base of charts with an x and
a y axis

=head1 SYNOPSIS

	# XYChart is abstract; you use its subclasses, which differ only in
	# the type their series have by default:
	use Term::Fabulous::Widget::LineChart;      # line
	use Term::Fabulous::Widget::AreaChart;      # area
	use Term::Fabulous::Widget::BarChart;       # bar
	use Term::Fabulous::Widget::ScatterPlot;    # scatter

	my $chart = Term::Fabulous::Widget::LineChart->new(
		title  => 'Requests per second',
		labels => [qw(Mon Tue Wed Thu Fri)],           # a category axis
		curve  => 'monotone',                          # for all series
		y_axis => { title => 'req/s', min => 0 },
		series => [
			{ name => 'api', data => [ 120, 135, 160, 158, 171 ] },
			{ name => 'web', data => [ 80, 82, 95, 110, 104 ], line_style => 'dashed' },
			{ name => 'jobs', type => 'bar', data => [ 20, 25, 18, 30, 27 ] },
		],
	);

	# Points with x values: numbers, dates or labels
	my $temperatures = Term::Fabulous::Widget::LineChart->new(
		x_axis => { format => '%H:%M' },
		series => [ { name => 'outside', data => [ [ '2026-06-01 06:00', 12.5 ], [ '2026-06-01 12:00', 21.0 ] ] } ],
	);

	# More data: one point for each series, here in a new category
	$chart->append( 'Sat', { api => 180, web => 99, jobs => 22 } );
	$chart->max_points(300);    # every series keeps its newest 300 points

	# Changes show in the next frame
	$chart->set_series( web => ( type => 'area', fill_opacity => 0.4 ) );
	$chart->stacked('percent');
	$chart->on( SeriesHover => sub ($event) { ... } );

=head1 DESCRIPTION

An XYChart draws one or more I<series> of data points against an x axis
and a y axis. The four subclasses are the same widget with a different
default series type: lines through the points, filled areas under them,
bars, or single points. Any chart can mix the types: a bar chart may
carry a line series for a target, a line chart an area for a range.
L<Term::Fabulous::Widget::Histogram> and
L<Term::Fabulous::Widget::Sparkline> are XYCharts too, with their own
pages.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-line-chart.svg" alt="A line chart with three smooth lines for Web, iOS and Android over the months of a year, a legend at the top, y axis labels with a title at the left and month labels below"></p>

=end html

The program is F<examples/widgets/line-chart.pl>.

The chart lays itself out in the room it has: the title and legend from
L<Term::Fabulous::Widget::Chart>, the y axis labels at the left, the x
axis labels below, axis titles when given, and the plot in between. The
y axis chooses round ticks that land exactly on rows, so every grid line
lies beside its label; the x axis chooses ticks whose labels do not
touch. Lines are drawn in Braille dots (a quarter cell wide, an eighth
cell high), areas and bars in block characters to an eighth of a cell;
L</Rendering styles> has the alternatives.

This page covers everything the XY charts share: L</SERIES> (what a
series is and the forms its data takes), L</AXES> (kinds of x values,
the axis options, logarithmic and time axes), L</STACKING>, L</LOOKS>
(curves, rendering styles, points, line styles, value labels, horizontal
bars), L</DATA> (transforms, cutting series to a range, live data),
L</HOVER>, and then the reference: L</CONSTRUCTOR>, L</METHODS>,
L</EVENTS>, L</KDL PROPERTIES> and the L</SUBCLASS INTERFACE>. Title,
legend, colors, themes and the hover mechanics are on
L<Term::Fabulous::Widget::Chart>. For an introduction to all chart
widgets, read L<the charts chapter of the manual|Term::Fabulous::Manual::Charts>;
complete programs are in L<Term::Fabulous::Cookbook::Charts>,
L<Term::Fabulous::Cookbook::ChartTechniques> and
L<Term::Fabulous::Cookbook::ChartStyles>.

=head1 SERIES

A series is a named list of data points drawn in one color: a line, an
area, a group of bars or a set of points. Give the series to the
constructor as C<series>, an array of hashes, or add them later with
C<add_series>; every method of L<Term::Fabulous::Role::HasSeries> is
available (C<set_series>, C<set_data>, C<add_points>, C<append>,
C<remove_series>, C<hide_series>, ...).

=head2 Series keys

	{
		name  => 'api',             # unique; default "Series 1", "Series 2", ...
		type  => 'line',            # line, area, bar or scatter; default: the chart's type
		data  => [ 3, 5, 4 ],       # see Data forms
		color => '#3987e5',         # default: the next palette color
		%options,                   # the drawing options below
	}

C<color> takes every form of L<Term::Fabulous::Color> (C<'#3987e5'>,
C<'rgb(57, 135, 229)'>, C<[ 57, 135, 229, 255 ]>, ...) and a packed
C<0x3987e5> integer; an alpha below 255 makes the series' areas and bars
more translucent. How series get their colors is described in
L<Term::Fabulous::Widget::Chart/Colors and themes>. A key the series does
not know dies, with the list of known keys in the message.

Besides C<name>, C<type>, C<data> and C<color>, a series takes these
options. Every one of them has a default. The options from C<marker> to
C<value_labels> can also be set on the chart for all of its series (as
constructor parameters or accessors of the same name): a series uses its
own value when it has one, else the chart's, else the default.

=over

=item C<marker>

The rendering style: see L</Rendering styles>. Default: C<braille> for
lines and points, C<block> for areas and bars.

=item C<curve>, C<tension>

How the line runs from point to point: C<linear> (the default),
C<step>, C<monotone>, C<natural>, an easing name, ...; see L</Curves>.
C<tension> (0 to 1, default 0) tightens the C<catmull-rom> curve.

=item C<line>

For an area: true draws a line along its top. Default: false (block
fills show the edge to an eighth of a cell on their own).

=item C<line_style>

C<solid> (the default), C<dashed> or C<dotted>; see L</Line styles>.

=item C<points>, C<point>

C<points> true marks every data point of a line or area series (default:
false). C<point> is the mark: C<dot>, C<square> or a single character
one column wide; default: a bullet on lines and areas, C<square> on
scatter series. See L</Points>.

=item C<fill_opacity>

0 to 1: how much of the area or bar color covers the background.
Default: 0.6 for areas, 0.8 for stacked areas, 1 for bars.

=item C<transform>

Steps that prepare the data before it is drawn; see L</Preparing data>.
Default: none.

=item C<max_points>

A positive integer: the series keeps only its newest points; see
L</Live data>. Default: no limit.

=item C<span_gaps>

True draws the line across missing values instead of leaving a gap.
Default: false.

=item C<value_labels>

For bars: true writes the value of each bar above (or right of) it.
Default: false. See L</Value labels>.

=item C<stack>

A group name: series of the same type with the same group name stack on
each other, whatever C<stacked> says. See L</STACKING>.

=item C<from>, C<to>

x values in the form of the axis (a number, a date, a category label):
the series is drawn only from C<from> to C<to>, either may be left out.
See L</From, to and span>.

=item C<trend>

True adds a dashed least-squares line through the points, in the
series' color, from the smallest x to the largest. Default: false.

=item C<visible>

False hides the series (also from the legend and the axes); its data is
kept. C<show_series> and C<hide_series> change it. Default: true.

=back

An option a series does not use (C<curve> on bars) is accepted and
ignored, with the exception of C<marker>: a marker the type cannot draw
with dies (C<block> on a line).

=head2 Data forms

	data => [ 3, 5, undef, 4 ]                                     # y values; x is the index (or the label)
	data => [ [ 1, 3 ], [ 2, 5 ], [ 4, 4 ] ]                       # [ x, y ] points
	data => [ [ '2026-06-01', 3 ], [ '2026-06-02', 5 ] ]           # dates as x
	data => [ [ 'Mon', 3 ], [ 'Tue', 5 ] ]                         # labels as x
	data => [ { x => 1, y => 3 }, { x => 2, y => 5 } ]             # hashes

Each point is a y value (its x is the point's position, 0, 1, 2, ..., or
the label at that position), an C<[ x, y ]> pair, or a hash with C<x>
and C<y>. A y value is a finite number or C<undef>, a gap: lines and
areas stop before a gap and start again after it (unless C<span_gaps>),
bars and points leave it out. What the x values may be, and what they
make of the x axis, is explained in L</What the x values are>.

The chart keeps the data as you gave it, and C<< $chart->series($name) >>
returns it: y values as numbers, C<[ x, y ]> pairs as pairs (hashes
come back as pairs too), x values unchanged. Transforms, sorting and
stacking happen each time a frame is drawn.

=head2 Several series

Series are drawn in the order they were added, layer by layer: areas,
then bars, then lines, then points; so a line stays visible over an
area of the same chart. The legend lists them in order. Each gets the
next color of the palette; a series keeps its color when others before
it are removed. While the pointer is on a series, that series is drawn
last in its layer, unless it is part of a stack (see L</HOVER>).

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-line.svg" alt="A line chart of three series, the average monthly temperatures of Lisbon, Berlin and Oslo, each in its own palette color with a dot on every month and a legend at the top"></p>

=end html

The program is in L<Term::Fabulous::Cookbook::Charts/Draw a line chart with labels and points (LineChart)>.

=head1 AXES

=head2 What the x values are

The x axis is a I<category>, a I<linear>, a I<logarithmic> or a I<time>
axis. By default (C<< x_axis =E<gt> { type =E<gt> 'auto' } >>) the chart
reads it from the data:

=over

=item *

With C<labels>, or when the points have no x values and a series draws
bars, the axis is a category axis: one slot per label (or per position),
in order. Points with x values on a category axis name their category;
new labels are appended in the order they appear.

=item *

When every x value is a number, the axis is linear: points are placed
by value, lines run from the smallest x to the largest (the points are
sorted), and bars are centered on their x and as wide as the smallest
distance between two bars.

=item *

When every x value is a date, the axis is a time axis. A date is a
string like C<2026-06>, C<2026-06-01>, C<2026-06-01 14:30> or
C<2026-06-01T14:30:15> (local time; with a trailing C<Z> after the time,
as in C<2026-06-01 14:30Z>, UTC; the exact forms are listed in
L<Term::Fabulous::Widget::Table::Value/date_interval>), or any object
with an C<epoch> method (DateTime, Time::Piece, Time::Moment). Epoch
seconds are numbers, so they make a linear axis unless the axis type is
C<time>. See L</Time axes>.

=item *

Points without x values and no bars make a linear axis of the point
positions 0, 1, 2, ... (lines and areas with many points, such as
samples).

=back

Set C<type> in C<x_axis> to decide yourself: C<category>, C<linear>,
C<log> or C<time>. A value the axis cannot show then dies when the frame
is drawn (a label on a linear axis), with the series and the value in
the message. On a category axis every x value is a label: numbers too,
and a date object becomes its C<YYYY-MM-DD> date in local time.

=head2 Axis keys

C<x_axis> and C<y_axis> are hashes; every key is optional. The y axis
shows the values; with C<horizontal> bars the two change places on the
screen, but the keys keep their meaning: C<y_axis> still describes the
values. Some keys apply only to some kinds of axis, as noted; on other
axes they are accepted and have no effect. An unknown key or an invalid
value dies when the hash is given, with the known keys in the message.

=over

=item C<type>

x: C<auto> (the default), C<category>, C<linear>, C<log> or C<time>. y:
C<linear> (the default) or C<log>.

=item C<min>, C<max>

Fixed ends: numbers on a linear or logarithmic axis (greater than 0 on
a logarithmic one), dates or epoch seconds on a time axis, and either
on an C<auto> x axis (a date counts as its epoch seconds there, whatever
kind the data makes the axis); C<min> must be less than C<max>. An end
that breaks these rules dies when the axis is given, so a chart never
fails while it is drawn. Without them the axis covers the data, rounded
out to the next ticks (see C<nice>); a linear y axis of bars or areas
includes 0 (see C<zero>). A category axis has no ends to set.

=item C<title>

A string: the title of the y axis is written above its values, that of
the x axis centered below its labels. With horizontal bars the titles
stay with their axes: the y axis title is centered below the values at
the bottom, the x axis title stands above the categories at the left.

=item C<format>

How tick labels (and the value labels of bars) are written. On a linear
or logarithmic axis: C<auto> (the default), C<si>, C<integer>,
C<percent>, a C<sprintf> format with a C<%>, or a code reference. On a
time axis: a L<POSIX/strftime> format or a code reference. With the x
axis type C<auto>, a format with a C<%> serves as either, whichever
kind the axis turns out to be. Category labels are shown as they are.
See L<Term::Fabulous::Chart::Format>.

=item C<ticks>

Linear axes: the number of ticks wanted; the chart takes the nearest
number whose ticks are round and fit.

=item C<step>

Linear axes: a fixed distance between ticks.

=item C<grid>

Grid lines at the ticks: C<0> or C<1> (solid), or C<solid>, C<dashed>
or C<dotted>. Default: solid lines for the value axis, none for the x
axis. A category axis with bars has no grid lines (the bars stand
between them). Where solid lines of both axes cross, they join.

=item C<visible>

False hides the tick labels (the plot takes their room; the axis title
stays). Default: true.

=item C<zero>

Linear y axes: whether the axis includes 0. Default: true when a bar or
area series is drawn or series are stacked, else false, so a line of
values from 1200 to 1300 fills the plot.

=item C<nice>

Linear axes: false keeps the ends of the axis at the data instead of
rounding them out to ticks. Default: true (except for histograms, whose
bins set the ends).

=item C<utc>

Time axes: true labels the ticks in UTC instead of local time, and puts
them on UTC boundaries. Default: false.

=item C<span>

Linear and time x axes: how much of x is shown, counted back from the
newest point (C<3600> for the last hour of epoch seconds); older points
are neither drawn nor counted for the y axis. See L</From, to and span>.

=item C<base>

Logarithmic axes: the base, a number greater than 1. Default: 10.

=back

	y_axis => { title => 'ms', min => 0, max => 500, ticks => 6, format => 'integer' },
	x_axis => { type => 'time', format => '%H:%M', utc => 1, grid => 'dotted' },

Grid lines in all three styles are shown in
L<Term::Fabulous::Cookbook::ChartStyles/Line styles, gaps, bar widths, stack groups and grid lines>.

=head2 Logarithmic axes

	y_axis => { type => 'log' },
	x_axis => { type => 'log', base => 2 },

C<< type =E<gt> 'log' >> on either axis puts every power of C<base> the
same distance from the next, for data that spans orders of magnitude or
grows by a constant factor. The ticks are the powers (1, 10, 100, 1k,
...); where they would crowd, only every second (third, ...) power is
labeled. Values of zero or below have no place on it: lines get a gap
there, bars and points are left out. Bars and areas grow from the low
end of the axis.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-log-scale.svg" alt="The same two series twice: on a linear axis the small values lie flat on the bottom, on a logarithmic axis both series rise as nearly straight lines"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartTechniques/Show values of very different sizes (logarithmic axis)>.

=head2 Time axes

A time axis places points by their moment and labels ticks on calendar
boundaries: every few seconds, minutes or hours, days, weeks (Mondays),
months or years, whichever the room allows. Without a C<format> the
labels fit the interval (C<06:00>, with the date at midnight; C<Jun 3>;
C<Feb>, with the year in January; C<2026>). Ticks are placed and
labeled in local time, in UTC with C<< utc =E<gt> 1 >>. The x values of
the points can be date strings, epoch numbers (with
C<< type =E<gt> 'time' >>) or date objects; mixed forms are fine. A time
axis needs x values: a series of plain y values dies when the frame is
drawn. See L<Term::Fabulous::Chart::Scale::Time> for the tick
intervals.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-time-series.svg" alt="Hourly temperatures over four days on a time axis labeled with dates at midnight and hours between: a solid measured line, a dashed forecast and a shaded area under part of the measurements"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartTechniques/Plot values over time (time axis, from and to, a dashed forecast)>.

=head1 STACKING

	stacked => 1,                        # bars on bars, areas on areas
	stacked => 'percent',                # every stack is 100%
	series  => [ { name => 'a', stack => 'left' }, { name => 'b', stack => 'left' }, { name => 'c', stack => 'right' } ],

With C<< stacked =E<gt> 1 >> every bar series stands on the bar series
before it and every area series lies on the area series before it, at
each x; the y axis covers the totals. Positive and negative values stack
in their own directions from the baseline. C<< stacked =E<gt> 'percent' >>
divides each value by the total of its stack (the sum of the absolute
values at that x), so every stack reaches 100%, and the value axis
shows percentages. C<stacked> does not stack lines and points.

The C<stack> option of a series puts it in a named group: series of the
same type and group stack on each other, whatever C<stacked> says, and
bars of different groups stand side by side in their slot. This also
stacks line or scatter series that share a group name. With
C<stacked>, the bars and areas without a group name form one group of
their own. Stacked areas are drawn more opaque (0.8) than single ones.

Hover and the C<SeriesHover> event report a point's own value, not the
stacked total; value labels on bars show the total of each stack.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-stacked-areas.svg" alt="Two stacked area charts of electricity from coal, gas, wind and solar from 2016 to 2026: the amounts in TWh on the left, each source's share of 100 percent on the right"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::Charts/Stacked areas and shares of 100% (AreaChart)>;
stacked bars are in
L<Term::Fabulous::Cookbook::Charts/Grouped, stacked and horizontal bars (BarChart)>,
and two named stack groups side by side in
L<Term::Fabulous::Cookbook::ChartStyles/Line styles, gaps, bar widths, stack groups and grid lines>.

=head1 LOOKS

=head2 Curves

	curve => 'monotone',                       # for all series
	series => [ { name => 'a', data => \@a, curve => 'step' } ],

The C<curve> of a line or area series says how the line runs between two
points. All curves pass through every point:

=over

=item C<linear> (the default)

Straight segments.

=item C<step>, C<step-after>, C<step-before>, C<step-middle>

Horizontal and vertical segments, for counters and states. With
C<step-after> (C<step> for short) each value holds until the next
point, where the line jumps; with C<step-before> the line jumps to the
next value right after a point; with C<step-middle> it jumps halfway
between two points.

=item C<monotone>

A smooth curve that never overshoots and is flat at every high and low:
the best smooth curve for data.

=item C<catmull-rom>, C<natural>

Smooth splines through the points; they may overshoot. C<tension> (0 to
1, default 0) tightens C<catmull-rom>; 1 gives straight lines.

=item an easing name or a code reference

Each segment follows an easing function (C<ease-in-out-sine>,
C<ease-out-bounce>, ... from L<Term::Fabulous::Chart::Easing>) or your
own function from C<t> (0 to 1) to the share of the change:
C<< curve =E<gt> sub ($t) { $t ** 2 } >>.

=back

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-curves.svg" alt="Six small charts of the same seven points connected linear, step, monotone, catmull-rom, ease-in-out-sine and ease-out-bounce"></p>

=end html

Details and the full list are in L<Term::Fabulous::Chart::Curve>; the
program is in
L<Term::Fabulous::Cookbook::ChartStyles/Connect points with curves and easings (curve)>.

=head2 Rendering styles

	marker => 'braille',                          # for all series
	series => [ { name => 'a', type => 'bar', marker => 'sextant' } ],

A chart draws into subpixels, several per terminal cell, and turns each
cell into one character with two colors. The C<marker> of a series picks
the character set and so the resolution:

=over

=item C<braille>

2 x 4 subpixels per cell, the finest: the default for lines and points.
One foreground color per cell, so where lines cross, the cell takes the
color of the line drawn last.

=item C<block>

1 x 8 subpixels (horizontal bars: 8 x 1): eighth blocks, the default for
areas and bars, whose tops are placed to an eighth of a cell.

=item C<half>, C<quadrant>, C<sextant>

1 x 2, 2 x 2 and 2 x 3 subpixels, two colors per cell: for fills in
terminals without a font that joins Braille dots, or for a coarser,
pixel look. Not every font has the sextants.

=item C<box>

For lines: box drawing characters, one row per column, as text charts
have been drawn for decades. Coarse, but every terminal and font shows
it. Like the other markers it stays inside the plot, also when a fixed
x range or a span leaves points outside.

=back

Lines take C<braille>, C<half>, C<quadrant>, C<sextant> and C<box>;
areas and bars C<block>, C<braille>, C<half>, C<quadrant> and
C<sextant>; points everything but C<block> and C<box>. A C<marker> set
on the chart applies to the series that can draw with it; the others
keep their default. A series' own C<marker> must suit its type, or it
dies. The line along the top of an area (C<line>) and the points of
lines and areas are always drawn in Braille. More on how cells get
their colors: L<Term::Fabulous::Chart::Marker>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-styles.svg" alt="Nine small charts of one wave: lines in Braille, half blocks, quadrants, sextants and box drawing lines, an area in eighth blocks, and bars in quadrants, blocks and Braille"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartStyles/Draw with Braille, blocks or box lines (marker)>.

=head2 Points

	points => 1,                                     # mark the points of every line and area
	series => [ { name => 'a', points => 1, point => 'x' } ],
	Term::Fabulous::Widget::ScatterPlot->new( point => 'dot', ... );

C<points> marks the data points of a line or area series; a scatter
series is nothing but points. The mark is the series' C<point>: C<dot>
(one Braille dot), C<square> (four dots, placed to a quarter cell: the
default of scatter series) or any single character one column wide
(C<x>, C<+>, C<o>; a bullet is the default of lines and areas).
Characters are placed on the cell their point falls in; dots and
squares at the subpixel. The legend shows a scatter series by its
character, or by a circle for dots and squares.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-scatter.svg" alt="A scatter plot of petal length and width of three species as three clusters of points, two drawn as Braille squares and the largest flowers as diamond characters, and a dashed trend line through each of the two larger species"></p>

=end html

Points on lines are shown in
L<Term::Fabulous::Cookbook::Charts/Draw a line chart with labels and points (LineChart)>,
the scatter plot above in
L<Term::Fabulous::Cookbook::Charts/A scatter plot with trend lines (ScatterPlot)>.

=head2 Line styles

	series => [ { name => 'forecast', data => \@forecast, line_style => 'dashed' } ],

C<line_style> draws a line C<solid> (the default), C<dashed> or
C<dotted>; the pattern runs on from segment to segment. A trend line
(C<trend>) is always dashed, with a longer pattern than C<dashed>, so
the two can be told apart.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-options.svg" alt="Six small charts: a solid, a dashed and a dotted line; a line with a gap next to one drawn across the gap; an area with a line and a mark on every point; narrow bars; bars of 2025 and 2026 in two stacks per quarter; a line over dashed vertical and solid horizontal grid lines"></p>

=end html

The picture also shows gaps and C<span_gaps>, an area with C<line> and
C<points>, a narrow C<bar_width>, two C<stack> groups and grid lines;
the program is in
L<Term::Fabulous::Cookbook::ChartStyles/Line styles, gaps, bar widths, stack groups and grid lines>.

=head2 Value labels

	value_labels => 1,

Writes the value of every bar over its top (right of its end, when
horizontal; below the end of a negative bar), of a stack its total, in
the format of the value axis. Without a C<format>, all labels of a
chart have as many decimals as the value that needs the most (C<48.0>
beside C<51.2>). A plot of six rows or more keeps a row free above it
for the labels of the highest bars. Labels that would touch a neighbor
are left out, so narrow bars show every other value. Lines, areas and
points have no value labels; use L</HOVER>.

=head2 Horizontal bars

	Term::Fabulous::Widget::BarChart->new( horizontal => 1, labels => \@names, ... );

Turns the chart on its side: categories down the left, values along the
bottom, bars growing to the right. For long category names, and when
there are many categories. A horizontal chart shows bar series only:
adding a series of another type dies, and so does turning a chart with
such a series horizontal (the chart stays as it was). The axis hashes
keep their meaning (C<y_axis> describes the values).

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-bars.svg" alt="Three bar charts: grouped bars with their values above them, stacked bars, and horizontal bars of four pages with their values right of the bars"></p>

=end html

The program, with grouped, stacked and horizontal bars and value labels,
is in L<Term::Fabulous::Cookbook::Charts/Grouped, stacked and horizontal bars (BarChart)>.

=head2 Bar width

	bar_width => 0.4,

C<bar_width> (0 to 1, default 0.7) is the share of a category slot the
bars of the slot take together; the rest is the gap between slots.
Grouped bars (several bar series) divide the share equally and are all
a whole number of subpixels wide. Every bar is at least one subpixel
wide. On a numeric or time x axis the slot is the smallest distance
between two bars. The picture under L</Line styles> shows bars with a
C<bar_width> of 0.4.

=head1 DATA

=head2 Preparing data

	transform => 'cumulative',                                        # for all series
	series => [
		{ name => 'raw',      data => \@samples },
		{ name => 'smoothed', data => \@samples, transform => [ [ 'moving_average', 7, 'center' ] ] },
		{ name => 'indexed',  data => \@prices,  transform => [ 'sort', [ 'index', 100 ] ] },
	],

A C<transform> lists steps that prepare the points before a frame is
drawn: C<normalize>, C<share>, C<zscore>, C<index>, C<cumulative>,
C<difference>, C<rate>, C<moving_average>, C<exponential>, C<median>,
C<gaussian>, C<scale>, C<offset>, C<clip>, C<abs>, C<sort>,
C<resample>, C<downsample>, C<regression>, or a code reference of your
own. The steps run again whenever the data changes, so live data stays
prepared. A series with a transform of its own does not run the
chart's. Every step, with its arguments and an example, is described in
L<Term::Fabulous::Chart::Transform/Steps>.

The steps get the x values as numbers: the positions 0, 1, 2, ... of
points without x, the category numbers on a category axis, epoch
seconds on a time axis. On numeric and time axes the points of lines
and areas are sorted by x before the steps run. Stacking happens after
the steps, so a stack adds up the prepared values.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-transform.svg" alt="Daily visits as a dim raw line with a 7-day moving average and a dashed exponentially smoothed line over it, and below it share and bond prices both indexed to 100 at day 1"></p>

=end html

The chart has no second y axis: two scales on one plot invite misreading.
To compare series of different sizes, use the C<index> transform (both
start at 100), C<normalize> or C<zscore>, or put two charts side by side.
The program in the picture is in
L<Term::Fabulous::Cookbook::ChartTechniques/Smooth noisy data and index it to 100 (transforms)>.

=head2 From, to and span

	series => [ { name => 'forecast', data => \@all, from => '2026-07-01', line_style => 'dashed' } ],
	x_axis => { span => 300 },     # the last five minutes

C<from> and C<to> of a series cut it to that range of x. Lines and the
tops of areas are cut with the ends interpolated, so a dashed forecast
can start exactly where the measured data ends; bars and points outside
the range are left out. The points outside do not count for the axes.
The picture under L</Time axes> shows a forecast and a shaded area cut
this way.

C<span> of the x axis shows only the last so much of x (in the unit of
the axis: seconds for a time axis), counted from the newest point of all
series, so a live chart scrolls with its data; the points that scrolled
out do not count for the y axis either, so a peak leaves the axis when
it leaves the plot. The points stay in the series, where they take
memory but little drawing time (lines and areas are drawn only where
they reach into the plot); use C<max_points> to drop them.

=head2 Live data

	my $chart = Term::Fabulous::Widget::LineChart->new(
		x_axis     => { type => 'time', span => 60 },
		max_points => 240,
		series     => [ { name => 'cpu' }, { name => 'mem' } ],
	);

	# In a timer, four times a second:
	$chart->append( Time::HiRes::time(), { cpu => cpu_load(), mem => memory_use() } );

C<append> adds one point to several series at once, at the same x (or
at the next position, with C<undef>); C<add_points> adds to one series.
C<max_points> (of the chart or a series) drops the oldest points, so the
chart does not grow without end; C<span> on the x axis keeps the plot
on the newest points. Every change marks the chart for the next frame;
only the cells that changed are sent to the terminal, so a chart can
take many updates per second. For charts that need a given time window
even when no data arrives, set C<min> and C<max> of the x axis from the
timer instead. A complete program is in
L<Term::Fabulous::Cookbook::ChartTechniques/A live chart that follows new data (append, max_points, span)>.

=head1 HOVER

While the mouse pointer is on a series, the chart emphasizes it and
fades the others, and fires a C<SeriesHover> event with the series, the
nearest data point, its label and its value. The label is the category
on a category axis, the moment in the axis' C<format> on a time axis
(C<%Y-%m-%d %H:%M> without a string format), and the x value as a plain
number otherwise. The value is the point's own value after the
transforms, not a stacked total. Thin lines are hit from the
neighboring cell too. C<highlight> emphasizes a series from the
program. How it works and how to turn it off:
L<Term::Fabulous::Widget::Chart/Hover and emphasis> and
L<Term::Fabulous::Event::SeriesHover>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-hover.svg" alt="A stacked area chart of closed issues per team with the area under the mouse pointer emphasized, the others faded, and a status line that names the team, the week and the number of issues"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartStyles/Show details of the point under the pointer (SeriesHover, highlight)>.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::LineChart->new(%parameters);

All parameters are optional. Besides those of
L<Term::Fabulous::Widget::Chart/CONSTRUCTOR> (C<title>, C<legend>,
C<palette>, C<theme>, the colors, C<hover>, C<highlight>, and the Box
parameters), the XY charts take:

=over

=item C<series>

An array reference of series hashes; see L</Series keys>. Default: none.

=item C<labels>

An array reference of strings: the categories of the x axis, in order.
Makes the x axis a category axis. Default: C<undef> (no labels; a
category axis then takes its labels from the data, see
L</What the x values are>).

=item C<x_axis>, C<y_axis>

Hash references with the keys of L</Axis keys>. Default: C<{}>. Unknown
keys and invalid values die.

	x_axis => { type => 'time', format => '%H:%M' },
	y_axis => { title => 'req/s', min => 0 },

=item C<stacked>

0 (the default), 1 or C<percent>; see L</STACKING>.

=item C<horizontal>

A boolean. Default: false. See L</Horizontal bars>.

=item C<bar_width>

A number from 0 to 1. Default: 0.7.

=item C<marker>, C<curve>, C<tension>, C<line>, C<line_style>, C<points>, C<point>, C<fill_opacity>, C<transform>, C<max_points>, C<span_gaps>, C<value_labels>

The series options of the same names, for every series without one of
its own; see L</Series keys>. A value a series type cannot use is kept
for the series that can (a C<curve> applies to lines and areas, not to
bars). A C<marker> must be one that some series type can draw with.
Default: none, so each series uses its own value or the default of the
option.

=back

=head1 METHODS

Every parameter except C<series> has an accessor of the same name:
without an argument it returns the value, with one it checks and sets
it, returns the new value, and the chart redraws in the next frame. An
invalid value dies and leaves the chart as it was.

	$chart->stacked('percent');
	$chart->curve('monotone');          # for every series without a curve of its own
	my $axis = $chart->x_axis;           # a copy, with type filled in

C<labels>, C<x_axis> and C<y_axis> return copies; C<x_axis> and
C<y_axis> replace the whole hash (merge yourself:
C<< $chart->y_axis( { %{ $chart->y_axis }, max => 10 } ) >>).
C<transform> only sets, and returns nothing. The series accessors
(C<curve>, C<marker>, ...) return the chart-wide value or C<undef>;
C<undef> removes it.

The series methods come from L<Term::Fabulous::Role::HasSeries>:

=over

=item *

Adding and removing series:
L<add_series|Term::Fabulous::Role::HasSeries/add_series>,
L<remove_series and clear_series|Term::Fabulous::Role::HasSeries/remove_series, clear_series>.

=item *

Reading them:
L<series_names and has_series|Term::Fabulous::Role::HasSeries/series_names, has_series>,
L<series|Term::Fabulous::Role::HasSeries/series>.

=item *

Changing a series and its data:
L<set_series|Term::Fabulous::Role::HasSeries/set_series>,
L<set_data, add_points and clear_data|Term::Fabulous::Role::HasSeries/set_data, add_points, clear_data>,
L<append|Term::Fabulous::Role::HasSeries/append>.

=item *

Showing and hiding:
L<show_series, hide_series and is_series_visible|Term::Fabulous::Role::HasSeries/show_series, hide_series, is_series_visible>.

=item *

Options and series objects:
L<series_default|Term::Fabulous::Role::HasSeries/series_default>,
L<series_option|Term::Fabulous::Role::HasSeries/series_option>,
L<all_series and visible_series|Term::Fabulous::Role::HasSeries/all_series, visible_series>.

=back

and C<hovered>, C<revision> and C<effective_background> from
L<Term::Fabulous::Widget::Chart>.

=head1 EVENTS

C<SeriesHover> (L<Term::Fabulous::Event::SeriesHover>) when the pointer
moves onto another series, point or legend entry, or off them; and the
canvas events C<CanvasResize>, C<Mouse> and C<MouseMove>.

=head1 KDL PROPERTIES

In a KDL layout (see L<Term::Fabulous::Manual::KDL/KDL LAYOUT FILES>) an XY
chart takes the properties of L<Term::Fabulous::Widget::Chart/KDL PROPERTIES>
and these:

=for highlighter language=kdl

	use Term::Fabulous::Widget::LineChart as LineChart

	LineChart "load" {
		title "System load"
		labels "Mon" "Tue" "Wed" "Thu" "Fri"
		stacked #false
		curve "monotone"
		points #true
		max_points 100
		x_axis grid="dotted"
		y_axis title="load" min=0 format="%.1f"
		transform "moving_average" 3
		series "web" color="#61afef" line_style="dashed" {
			data 1.2 1.5 1.1 1.8 1.6
		}
		series "api" type="area" {
			point "Mon" 0.4
			point "Tue" 0.6
			transform "cumulative"
		}
	}

=over

=item C<labels "a" "b" ...>

The categories, as the C<labels> parameter.

=item C<x_axis key=value ...>, C<y_axis key=value ...>

The axis keys as properties (C<title>, C<min>, C<max>, C<format>,
C<ticks>, C<step>, C<grid>, C<visible>, C<zero>, C<utc>, C<span>,
C<base>, C<nice>, C<type>). Several nodes merge.

=item C<stacked>, C<horizontal>, C<bar_width>, C<marker>, C<curve>, C<tension>, C<line_style>, C<line>, C<points>, C<point>, C<fill_opacity>, C<max_points>, C<span_gaps>, C<value_labels>

As the parameters; booleans as C<#true> or C<#false>, C<stacked> also
as C<"percent">. On the chart, C<point> is the mark of the points
(C<point "dot">); inside a C<series> block a C<point> node is a data
point.

=item C<transform "step" args...>

One step of the chart's transform; repeat the node for several steps,
in order.

=item C<series "name" type="..." color="..." option=value ... { ... }>

A series: its name as the argument, C<type>, C<color> and the series
options of L</Series keys> as properties (C<stack="a">,
C<from="2026-06-01">, C<trend=#true>, ...), and in its block any number
of C<data> nodes (y values; C<#null> is a gap), C<point x y> nodes and
C<transform "step" args...> nodes, in order.

=back

Axes and labels are applied before the series, whatever their order in
the file, so the series' x values are read the way the axis says. Data
that comes from the program (live values, code references) is added
afterwards with the methods.

A horizontal bar chart of shares:

	use Term::Fabulous::Widget::BarChart as BarChart

	BarChart "tickets" {
		stacked "percent"
		horizontal #true
		labels "Mon" "Tue" "Wed"
		y_axis grid="dashed"
		series "open" { data 3 #null 4; }
		series "closed" color="#199e70" { data 5 6 7; }
	}

A complete program with charts from a layout is in
L<Term::Fabulous::Cookbook::ChartTechniques/Describe charts in a KDL layout (series, slices, transforms)>.

=head1 SUBCLASS INTERFACE

The four chart classes provide only C<default_series_type>. A chart with
other needs (L<Term::Fabulous::Widget::Histogram>,
L<Term::Fabulous::Widget::Sparkline>) overrides:

=over

=item C<prepare_series()>

Returns the x kind (C<category>, C<linear>, C<log>, C<time>), the
category labels, and the prepared series as hashes with C<series>,
C<name>, C<type>, C<xs>, C<ys> (numbers or C<undef>), and after
C<stack_series> C<lows> and C<highs>; optionally C<edges> (the
C<[ from, to ]> of each bar on the x axis) and C<labels> (what hover
calls each point).

=item C<stack_series(\@prepared)>

Adds C<lows>, C<highs> and C<group> to the prepared series.

=item C<fit_prepared( $width, $kind, $categories, $prepared )>

Gets what C<prepare_series> returned and the width of the plot area,
returns the same three values, changed: a sparkline shows the newest
bars that fit.

=item C<value_axis_edges()>

True to map the value axis to the edges of the plot instead of the
centers of its first and last cell (charts without axis labels).

=item C<draws_baseline()>

False leaves the baseline out.

=item C<default_bar_opacity(\@bars)>

The opacity of bars without a C<fill_opacity>; a histogram makes
overlapping bins translucent.

=item C<value_format()>

The format of the value axis and the value labels; C<percent> for
percent stacks by default.

=item C<check_series_type( $name, $type )>

Dies when the chart cannot show a series of that type now; called
before a series is added or changes its type.

=back

together with L<Term::Fabulous::Widget::Chart/SUBCLASS INTERFACE>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Chart>, L<Term::Fabulous::Widget::LineChart>,
L<Term::Fabulous::Widget::AreaChart>, L<Term::Fabulous::Widget::BarChart>,
L<Term::Fabulous::Widget::ScatterPlot>, L<Term::Fabulous::Widget::Histogram>,
L<Term::Fabulous::Widget::Sparkline>, L<Term::Fabulous::Role::HasSeries>,
L<Term::Fabulous::Chart::Transform>, L<Term::Fabulous::Chart::Curve>,
L<Term::Fabulous::Chart::Marker>, L<Term::Fabulous::Chart::Format>,
L<Term::Fabulous::Manual::Charts/CHARTS>, L<Term::Fabulous::Cookbook::Charts>,
L<Term::Fabulous::Cookbook::ChartTechniques>, L<Term::Fabulous::Cookbook::ChartStyles>.

=cut
