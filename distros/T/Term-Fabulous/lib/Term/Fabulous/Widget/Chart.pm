package Term::Fabulous::Widget::Chart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Hoverable;
use Term::Fabulous::Widget::Display;

class Term::Fabulous::Widget::Chart
	:isa(Term::Fabulous::Widget::Display)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:abstract
{
	use Carp qw(croak);
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow);
	use List::Util qw(max min sum0);
	use Scalar::Util qw(refaddr weaken);
	use Term::Fabulous::Check qw(boolean describe one_of);
	use Term::Fabulous::Chart::Palette qw(palette_colors is_palette_name palette_names chart_color mix_rgb is_light_rgb ink_colors);
	use Term::Fabulous::Chart::Surface;
	use Term::Fabulous::Event::SeriesHover;
	use Term::Fabulous::Termbox qw(TB_BOLD);

	use constant {
		DARK_SURFACE  => 0x1A1A19,    # the ink's base where the chart lies on nothing
		LIGHT_SURFACE => 0xFCFCFB,
		LEGEND_GAP    => 3,    # columns between legend entries in a row
	};

	my @LEGEND         = qw(auto top bottom left right none);
	my @ALIGN          = qw(left center right);
	my @THEME          = qw(auto dark light);
	my @INK_COLORS     = qw(title_color text_color label_color axis_color grid_color);
	my %SYMBOL_COLUMNS = ( line => 2, fill => 1, point => 1 );

	field $title       :param = undef;
	field $title_align :param = 'left';
	field $legend      :param = 'auto';
	field $palette     :param = 'default';
	field $theme       :param = 'auto';
	field $hover       :param = 1;
	field $hover_fade  :param = 0.7;
	field $highlight   :param = undef;
	field %_ink;    # the colors given for title_color, ..., as 0xRRGGBB

	field $_surface;    # the last frame's surface, for the mouse
	field @_targets;    # owner id => { key, series, index, label, value, x }
	field $_hovered;    # the target under the pointer, or undef

	# What the chart draws, from its own state; see SUBCLASS INTERFACE.
	method legend_entries;
	method draw_plot;
	method default_legend_position;

	ADJUST :params ( :$title_color = undef, :$text_color = undef, :$label_color = undef, :$axis_color = undef, :$grid_color = undef ) {
		my %given = ( title_color => $title_color, text_color => $text_color, label_color => $label_color, axis_color => $axis_color, grid_color => $grid_color );
		$self->_check_title( title => $title );
		one_of( $self, title_align => $title_align, @ALIGN );
		one_of( $self, legend      => $legend,      @LEGEND );
		one_of( $self, theme       => $theme,       @THEME );
		$palette    = $self->_checked_palette($palette);
		$hover      = boolean( $self, hover => $hover );
		$hover_fade = $self->_checked_fraction( hover_fade => $hover_fade );
		$self->_check_title( highlight => $highlight );

		foreach my $name (@INK_COLORS) {
			( $_ink{$name} ) = chart_color( $self, $name, $given{$name} ) if defined $given{$name};
		}

		weaken( my $weak_self = $self );
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on( MouseMove => sub ($event) { $weak_self->_pointer_moved($event) if defined $weak_self; return $continue } );
		$self->on( Mouse     => sub ($event) { $weak_self->_pointer_moved($event) if defined $weak_self; return $continue } );
		$self->on(
			OnHoverStopped => sub ($event) {
				$weak_self->_hover_target(undef) if defined $weak_self && refaddr( $event->target ) == refaddr($weak_self);
				return $continue;
			}
		);
	}

	method _fail ( $name, $expected, $value ) {
		croak ref($self) . ": $name must be $expected, got " . describe($value);
	}

	method _check_title ( $name, $value ) {
		$self->_fail( $name, 'a string or undef', $value ) if ref $value;
		return $value;
	}

	method _checked_fraction ( $name, $value ) {
		$self->_fail( $name, 'a number from 0 to 1', $value ) unless defined $value && !ref $value && $value =~ /\A(?:0|1|0?\.[0-9]+|1\.0*)\z/;
		return $value + 0;
	}

	# A palette name, or an array of colors (as 0xRRGGBB).
	method _checked_palette ($value) {
		return $value if is_palette_name($value);
		$self->_fail( 'palette', 'a palette name (' . join( ', ', palette_names() ) . ') or an array reference of colors', $value )
			unless ref $value eq 'ARRAY' && @$value;
		return [ map { ( chart_color( $self, 'palette color', $_ ) )[0] } @$value ];
	}

	# ---------------------------------------------------------------------
	# Changes and painting
	# ---------------------------------------------------------------------

	# A chart without a size in the layout takes the room it gets
	# (Term::Fabulous::Widget::Display).
	method natural_size () {
		return ( sizing_grow(), sizing_grow() );
	}

	# The background the chart is drawn on (Term::Fabulous::Widget's
	# background_below) as 0xRRGGBB; undef where there is none.
	method effective_background () {
		my $rgba = $self->background_below // return undef;
		return ( $rgba->[0] << 16 ) | ( $rgba->[1] << 8 ) | $rgba->[2];
	}

	# Besides its own state and the theme (Term::Fabulous::Widget::Display),
	# a chart is drawn from what it lies on and what the pointer is on.
	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->effective_background, defined $_hovered ? $_hovered->{key} : undef );
	}

	method paint () {
		my $background = $self->effective_background;
		my $look       = $self->_look($background);
		@_targets = ();
		$_surface = Term::Fabulous::Chart::Surface->new( columns => $self->columns, rows => $self->rows, background => $background );
		$self->_draw( $_surface, $look );
		$_surface->paint($self);
		return;
	}

	# Everything a frame is drawn with: colors and the emphasized series.
	method _look ($background) {
		my $mode     = $theme ne 'auto' ? $theme : defined $background && is_light_rgb($background) ? 'light' : 'dark';
		my $base     = $background // ( $mode eq 'light' ? LIGHT_SURFACE : DARK_SURFACE );
		my $ink      = ink_colors( $base, $mode );
		my %color    = map { my $short = s/_color\z//r; $short => $_ink{$_} // $ink->{$short} } @INK_COLORS;
		my $emphasis = $hover && defined $_hovered ? $_hovered->{series} : $highlight;
		return {
			mode       => $mode,
			background => $background,
			base       => $base,
			%color,
			palette  => ref $palette ? $palette : [ palette_colors( $palette, $mode ) ],
			emphasis => $emphasis,
			fade     => $hover_fade,
		};
	}

	# The color of a palette slot.
	method slot_color ( $look, $slot ) {
		my $colors = $look->{palette};
		return $colors->[ $slot % @$colors ];
	}

	# A series' color as the frame shows it: faded while another series
	# is emphasized.
	method shown_color ( $look, $series, $color ) {
		return $color if !defined $look->{emphasis} || !defined $series || $series eq $look->{emphasis};
		return mix_rgb( $color, $look->{base}, $look->{fade} );
	}

	method is_emphasized ( $look, $series ) {
		return defined $look->{emphasis} && defined $series && $series eq $look->{emphasis} ? 1 : 0;
	}

	# An owner id for what is drawn: what the pointer is on when it is
	# over the cells drawn with it.
	method register_target (%target) {
		$target{key} = join "\0", map { $_ // '' } @target{qw(series index)};
		push @_targets, \%target;
		return $#_targets;
	}

	method _draw ( $surface, $look ) {
		my ( $columns, $rows ) = ( $surface->columns, $surface->rows );
		my ( $left, $top, $right, $bottom ) = ( 0, 0, $columns, $rows );

		if ( defined $title && length $title && $rows >= 3 ) {
			my $width = Term::Fabulous::Chart::Surface->text_columns($title);
			my $x     = $title_align eq 'center' ? max( 0, int( ( $columns - $width ) / 2 ) ) : $title_align eq 'right' ? max( 0, $columns - $width ) : 0;
			$surface->text( $x, 0, $title, $look->{title}, flags => TB_BOLD, max => $columns );
			$top = $rows >= 12 ? 2 : 1;
		}

		my @entries  = $self->legend_entries($look);
		my $position = $legend eq 'auto' ? ( @entries >= 2 ? $self->default_legend_position : 'none' ) : $legend;
		my $layout;
		$layout = $self->_legend_layout( \@entries, $position, $left, $top, $right, $bottom ) if @entries && $position ne 'none';
		if ($layout) {
			( $left, $top, $right, $bottom ) = $layout->{plot}->@*;
			$self->_paint_legend( $surface, $look, $layout ) unless $position eq 'bottom';
		}
		my $at_bottom = $layout && $position eq 'bottom';
		if ( $right - $left < 2 || $bottom - $top < 1 ) {
			$self->_paint_legend( $surface, $look, $layout ) if $at_bottom;
			return;
		}
		my $used = $self->draw_plot( $surface, $left, $top, $right - $left, $bottom - $top, $look );
		return unless $at_bottom;

		# A legend at the bottom follows the rows the plot used, not the
		# rows its ticks left free below the axis.
		$layout->{y} = $top + min( $bottom - $top, $used // $bottom - $top ) + $layout->{gap};
		$self->_paint_legend( $surface, $look, $layout );
		return;
	}

	# ---------------------------------------------------------------------
	# Legend
	# ---------------------------------------------------------------------

	# An entry's value may be several texts (an amount and a share); they
	# are joined into one, in a column of their own each when the legend
	# lists the entries one below the other.
	sub _joined_values ( $entries, $in_columns ) {
		my @widths;
		foreach my $entry ( grep { ref $_->{value} } @$entries ) {
			foreach my $index ( 0 .. $entry->{value}->$#* ) {
				my $columns = Term::Fabulous::Chart::Surface->text_columns( $entry->{value}[$index] );
				$widths[$index] = $columns if !defined $widths[$index] || $columns > $widths[$index];
			}
		}
		return $entries unless @widths;
		return [
			map {
				my $entry = $_;
				!ref $entry->{value} ? $entry : {
					%$entry,
					value => join '  ',
					map {
						my $text = $entry->{value}[$_];
						$in_columns ? ( ' ' x ( $widths[$_] - Term::Fabulous::Chart::Surface->text_columns($text) ) ) . $text : $text
					} 0 .. $entry->{value}->$#*
				}
			} @$entries
		];
	}

	sub _entry_columns ($entry) {
		my $columns = $SYMBOL_COLUMNS{ $entry->{symbol} } + 1 + Term::Fabulous::Chart::Surface->text_columns( $entry->{label} );
		$columns += 2 + Term::Fabulous::Chart::Surface->text_columns( $entry->{value} ) if defined $entry->{value};
		return $columns;
	}

	sub _more_text ($hidden) {
		return "+$hidden more";
	}

	# Lays the legend out at one side of the area: where its entries go
	# and the area left for the plot. Entries that do not fit are left
	# out, and the last row (or line) says how many. Nothing when a row
	# could not show even one entry beside the count.
	method _legend_layout ( $entries, $position, $left, $top, $right, $bottom ) {
		my $width = $right - $left;
		$entries = _joined_values( $entries, $position eq 'left' || $position eq 'right' );
		if ( $position eq 'top' || $position eq 'bottom' ) {
			my @rows = ( { items => [], used => 0 } );
			foreach my $entry (@$entries) {
				my $columns = min( _entry_columns($entry), $width );
				push @rows, { items => [], used => 0 } if $rows[-1]{items}->@* && $rows[-1]{used} + LEGEND_GAP + $columns > $width;
				$rows[-1]{used} += ( $rows[-1]{items}->@* ? LEGEND_GAP : 0 ) + $columns;
				push $rows[-1]{items}->@*, [ $entry, $columns ];
			}
			my $room = $bottom - $top;
			splice @rows, max( 1, int( $room / 3 ) ) if @rows > max( 1, int( $room / 3 ) );
			my $hidden = @$entries - sum0( map { scalar $_->{items}->@* } @rows );
			my $more;
			if ($hidden) {
				my $last = $rows[-1];
				my $fits = sub { $last->{used} + LEGEND_GAP + length _more_text($hidden) <= $width };
				while ( $last->{items}->@* > 1 && !$fits->() ) {
					my $gone = pop $last->{items}->@*;
					$last->{used} -= LEGEND_GAP + $gone->[1];
					$hidden++;
				}

				# The one entry left is cut short rather than the count; when
				# that leaves it less than a letter of its label, the legend
				# is left out.
				if ( !$fits->() ) {
					my $item    = $last->{items}[0];
					my $columns = $width - LEGEND_GAP - length _more_text($hidden);
					return undef if $columns < $SYMBOL_COLUMNS{ $item->[0]{symbol} } + 3;
					$item->[1] = $columns;
					$last->{used} = $columns;
				}
				$more = { text => _more_text($hidden), x => $left + $last->{used} + LEGEND_GAP };
			}
			my $gap = $room - @rows >= 8 ? 1 : 0;
			return {
				kind => 'rows',
				rows => \@rows,
				more => $more,
				x    => $left,
				y    => $position eq 'top' ? $top : $bottom - @rows,
				gap  => $gap,
				plot => $position eq 'top' ? [ $left, $top + @rows + $gap, $right, $bottom ] : [ $left, $top, $right, $bottom - @rows - $gap ],
			};
		}

		# A column beside the plot, its entries centered vertically; values
		# line up at the right.
		my $room   = $bottom - $top;
		my $hidden = max( 0, @$entries - $room );
		my @shown  = @$entries[ 0 .. $#$entries - $hidden - ( $hidden ? 1 : 0 ) ];
		$hidden = @$entries - @shown;
		my $lines         = @shown + ( $hidden ? 1 : 0 );
		my $label_columns = max( map { Term::Fabulous::Chart::Surface->text_columns( $_->{label} ) } @$entries );
		my $value_columns = max( 0, map { Term::Fabulous::Chart::Surface->text_columns( $_->{value} // '' ) } @$entries );
		my $wanted        = max( map { $SYMBOL_COLUMNS{ $_->{symbol} } } @$entries ) + 1 + $label_columns + ( $value_columns ? 2 + $value_columns : 0 );
		my $columns       = min( max( $wanted, $hidden ? length _more_text($hidden) : 0 ), int( $width / 2 ) );
		return {
			kind          => 'column',
			entries       => \@shown,
			more          => $hidden              ? { text => _more_text($hidden) } : undef,
			x             => $position eq 'right' ? $right - $columns               : $left,
			y             => $top + max( 0, int( ( $room - $lines ) / 2 ) ),
			columns       => $columns,
			value_columns => $value_columns,
			gap           => 0,
			plot          => $position eq 'right' ? [ $left, $top, $right - $columns - 2, $bottom ] : [ $left + $columns + 2, $top, $right, $bottom ],
		};
	}

	method _paint_legend ( $surface, $look, $layout ) {
		my ( $x, $y ) = @$layout{qw(x y)};
		if ( $layout->{kind} eq 'column' ) {
			$self->_draw_entry( $surface, $look, $_, $x, $y++, $layout->{columns}, $layout->{value_columns} ) foreach $layout->{entries}->@*;
			$surface->text( $x, $y, $layout->{more}{text}, $look->{label}, max => $layout->{columns} ) if $layout->{more};
			return;
		}
		foreach my $row ( $layout->{rows}->@* ) {
			my $at = $x;
			foreach my $item ( $row->{items}->@* ) {
				$self->_draw_entry( $surface, $look, $item->[0], $at, $y, $item->[1], undef );
				$at += $item->[1] + LEGEND_GAP;
			}
			$y++;
		}
		$surface->text( $layout->{more}{x}, $y - 1, $layout->{more}{text}, $look->{label} ) if $layout->{more};
		return;
	}

	# One entry: its symbol in the series color, its label, and its value
	# (right-aligned in $value_columns, when given).
	method _draw_entry ( $surface, $look, $entry, $x, $y, $columns, $value_columns ) {
		my $emphasized = $self->is_emphasized( $look, $entry->{series} );
		my $faded      = defined $look->{emphasis} && !$emphasized;
		my $color      = $self->shown_color( $look, $entry->{series}, $entry->{color} );
		my $text       = $faded ? mix_rgb( $look->{text}, $look->{base}, $look->{fade} ) : $emphasized ? $look->{title} : $look->{text};
		my $owner      = $self->register_target( series => $entry->{series}, index => $entry->{index}, label => $entry->{label}, value => $entry->{raw_value} );

		my $symbol = $entry->{symbol} eq 'line' ? "\x{2501}\x{2501}" : $entry->{symbol} eq 'point' ? $entry->{glyph} // "\x{25CF}" : "\x{25A0}";
		my $end    = $x + $columns;
		my $at     = $x + $surface->text( $x, $y, $symbol, $color );
		$at++;
		my $value_room = defined $entry->{value} ? ( $value_columns // Term::Fabulous::Chart::Surface->text_columns( $entry->{value} ) ) + 2 : 0;
		$at += $surface->text( $at, $y, $entry->{label}, $text, max => max( 0, $end - $at - $value_room ), flags => $emphasized ? TB_BOLD : 0 );
		if ( defined $entry->{value} && $end - $at >= 2 ) {
			my $value_width = Term::Fabulous::Chart::Surface->text_columns( $entry->{value} );
			$surface->text( $end - $value_width, $y, $entry->{value}, $faded ? $text : $look->{label}, max => $end - $at - 1 );
		}
		$surface->set_owner( $_, $y, 'fill', $owner ) foreach $x .. $end - 1;
		return;
	}

	# ---------------------------------------------------------------------
	# Hover
	# ---------------------------------------------------------------------

	method _pointer_moved ($event) {
		return unless $hover && defined $_surface;
		my ( $x, $y ) = $self->cell_at($event);
		my $owner = defined $x ? $_surface->owner_near( $x, $y ) : undef;
		$self->_hover_target( defined $owner ? $_targets[$owner] : undef );
		return;
	}

	method _hover_target ($target) {
		my $old = defined $_hovered ? $_hovered->{key} : '';
		my $new = defined $target   ? $target->{key}   : '';
		return if $old eq $new;
		$_hovered = $target;
		$self->mark_changed;
		my %fields = defined $target ? map { $_ => $target->{$_} } grep { defined $target->{$_} } qw(series index label value x) : ();
		$self->fire_event( Term::Fabulous::Event::SeriesHover->new(%fields) );
		return;
	}

	# Ends the hover when the program took away what the pointer is on:
	# the hovered series or slice is none of the names still shown.
	method end_hover_unless_shown (@shown_names) {
		my $series = defined $_hovered ? $_hovered->{series} : undef;
		return unless defined $series;
		return if grep { $_ eq $series } @shown_names;
		$self->_hover_target(undef);
		return;
	}

	method hovered () {
		return undef unless defined $_hovered;
		return { map { $_ => $_hovered->{$_} } grep { defined $_hovered->{$_} } qw(series index label value x) };
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _changed_to ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $value;
	}

	method title (@new) {
		return $title unless @new;
		return $self->_changed_to( \$title, $self->_check_title( title => $new[0] ) );
	}

	method title_align (@new) {
		return $title_align unless @new;
		return $self->_changed_to( \$title_align, one_of( $self, title_align => $new[0], @ALIGN ) );
	}

	method legend (@new) {
		return $legend unless @new;
		return $self->_changed_to( \$legend, one_of( $self, legend => $new[0], @LEGEND ) );
	}

	method theme (@new) {
		return $theme unless @new;
		return $self->_changed_to( \$theme, one_of( $self, theme => $new[0], @THEME ) );
	}

	method palette (@new) {
		return ref $palette ? [@$palette] : $palette unless @new;
		$self->_changed_to( \$palette, $self->_checked_palette( $new[0] ) );
		return $self->palette;
	}

	method hover (@new) {
		return $hover unless @new;
		$self->_hover_target(undef) unless $new[0];
		return $self->_changed_to( \$hover, boolean( $self, hover => $new[0] ) );
	}

	method hover_fade (@new) {
		return $hover_fade unless @new;
		return $self->_changed_to( \$hover_fade, $self->_checked_fraction( hover_fade => $new[0] ) );
	}

	method highlight (@new) {
		return $highlight unless @new;
		return $self->_changed_to( \$highlight, $self->_check_title( highlight => $new[0] ) );
	}

	method _ink_color ( $name, @new ) {
		return $_ink{$name} unless @new;
		if ( defined $new[0] ) {
			( $_ink{$name} ) = chart_color( $self, $name, $new[0] );
		}
		else {
			delete $_ink{$name};
		}
		$self->mark_changed;
		return $_ink{$name};
	}

	method title_color (@new) { return $self->_ink_color( title_color => @new ) }
	method text_color  (@new) { return $self->_ink_color( text_color  => @new ) }
	method label_color (@new) { return $self->_ink_color( label_color => @new ) }
	method axis_color  (@new) { return $self->_ink_color( axis_color  => @new ) }
	method grid_color  (@new) { return $self->_ink_color( grid_color  => @new ) }

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			title       => 'scalar',
			title_align => 'scalar',
			legend      => 'scalar',
			theme       => 'scalar',
			hover       => 'boolean',
			hover_fade  => 'scalar',
			highlight   => 'scalar',
			palette     => \&_parse_palette,
			( map { $_ => \&_parse_ink_color } @INK_COLORS ),
		);
	}

	# palette "vivid", or palette "#3987e5" "#d95926" ...
	method _parse_palette ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'palette' takes a palette name or one or more colors" unless @args && !$kid->props->@* && !$kid->children->@*;
		$self->palette( @args == 1 && is_palette_name( $args[0] ) ? $args[0] : \@args );
		return;
	}

	method _parse_ink_color ($kid) {
		my $name = $kid->name;
		$self->_ink_color( $name => $self->kdl_value($kid) );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Chart - What all chart widgets have in common:
title, legend, colors and hover

=head1 SYNOPSIS

	# Chart is abstract; you use its subclasses:
	use Term::Fabulous::Widget::LineChart;

	my $chart = Term::Fabulous::Widget::LineChart->new(
		title       => 'Requests per second',
		legend      => 'bottom',               # auto, top, bottom, left, right, none
		palette     => 'classic',              # or [ '#3987e5', '#d95926', ... ]
		theme       => 'auto',                 # dark or light ink, from the background
		label_color => '#8b93a7',
		series      => [ { name => 'api', data => \@api }, { name => 'web', data => \@web } ],
	);

	$chart->on( SeriesHover => sub ($event) {
		$status->text( defined $event->series ? $event->series . ': ' . ( $event->value // '' ) : '' );
		return;
	} );
	$chart->highlight('api');    # emphasize one series from the program

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-chart.svg" alt="Four bar charts of the same data: the legend at the top, at the bottom under a centered title, at the right with the iOS series highlighted and the others faded, and at the left of a chart on a light panel with a right-aligned title"></p>

=end html

F<examples/widgets/chart.pl> shows the features of this page on four
bar charts: title alignment, legend positions, palettes, C<highlight>
and the light theme.

=head1 DESCRIPTION

The base class of the chart widgets:

=over

=item L<Term::Fabulous::Widget::LineChart>, L<Term::Fabulous::Widget::AreaChart>,
L<Term::Fabulous::Widget::BarChart>, L<Term::Fabulous::Widget::ScatterPlot>,
L<Term::Fabulous::Widget::Histogram>, L<Term::Fabulous::Widget::Sparkline>

Charts with an x and a y axis; see L<Term::Fabulous::Widget::XYChart>
for everything they share.

=item L<Term::Fabulous::Widget::PieChart>, L<Term::Fabulous::Widget::DonutChart>,
L<Term::Fabulous::Widget::PolarAreaChart>, L<Term::Fabulous::Widget::RadarChart>

Round charts.

=back

A chart is a L<Term::Fabulous::Widget::Display> that draws itself: give it
data, and it lays out its title, legend, axes and plot in whatever room
the layout gives it, and draws them again whenever the data, an option or
its size changes. Only cells that changed are sent to the terminal, so a
chart can be updated many times per second. Do not draw into a chart
with the canvas methods (C<put>, C<fill>, ...): the chart paints over
them in the next frame.

Without a C<sizing> in its C<layout>, a chart grows to the room its parent
has left (C<sizing_grow> in both directions); a size given for one
direction is kept, and only the other one grows. It has every parameter of a
L<Term::Fabulous::Widget::Box> as well (background, border, padding, ...).

L<Term::Fabulous::Manual::Charts> introduces the chart widgets and helps
you choose one; L<Term::Fabulous::Cookbook::Charts>,
L<Term::Fabulous::Cookbook::ChartTechniques> and
L<Term::Fabulous::Cookbook::ChartStyles> have complete programs.

=head2 Title and legend

The C<title> is drawn in bold in the chart's first row, at the left,
in the center or at the right (C<title_align>). A chart of 12 rows or
more leaves an empty row below it; a chart of fewer than 3 rows (such
as a sparkline) shows no title.

The legend lists the series (or, in pie charts, the slices) with their
colors: a short line for a line series, a square for areas, bars and
slices, the point character for scatter series. With
C<< legend =E<gt> 'auto' >> (the default), a chart shows a legend when it
has at least two entries: a single series is named by the title. Charts
with axes and radar charts put it at the C<top>; pie, donut and polar
area charts on the C<right>. C<top>, C<bottom>, C<left> and C<right> put
it there whatever the number of entries; C<none> hides it.

A legend at the top or bottom wraps into more rows when the entries do
not fit in one (up to a third of the chart's height); a legend beside
the plot lists one entry per row, centered vertically, takes at most
half of the chart's width and cuts long labels. When not all entries
fit, the legend ends with C<+N more>; a chart too narrow to show even
one entry beside that count (about 15 columns) has no legend. A legend
at the bottom sits right below the plot, also when the axis ticks leave
rows free.

=head2 Colors and themes

Every series (or slice) gets the next color of the C<palette> when it is
added, and keeps it when other series come and go; a C<color> of its own
wins. The palettes are described in L<Term::Fabulous::Chart::Palette>: the
C<default> palette's colors are chosen to stay apart for readers with
color vision deficiencies. A palette may also be an array of colors of
your own, used in their order; their alpha is ignored (give a series a
translucent C<color>, or a C<fill_opacity>, for translucency). With more
series than the palette has colors (eight in the named palettes), the
colors repeat; give such series colors of their own, or better, fewer
series.

The chart has no background of its own by default: it is drawn on the
background of its nearest ancestor with an opaque one, or on the
screen color of the theme (L<Term::Fabulous::Widget/background_below>),
and blends its translucent fills with it. Set C<background_color> to
give it one. The C<theme> chooses between dark and light ink and
palette steps; C<auto> (the default) looks at the background and picks
C<light> on a light one.

Text and lines that are not data are drawn in colors mixed from the
background and the ink of the theme, so they suit any background: the
title nearly in the ink color, legend text a little softer, the tick
labels and axis titles muted, axis lines faint, grid lines only one shade
off the background. Set C<title_color>, C<text_color>, C<label_color>,
C<axis_color> or C<grid_color> to use colors of your own.

=head2 Hover and emphasis

While the mouse pointer is on a series (its line, area, bars or points,
or its legend entry), the chart emphasizes it: the series keeps its color
and is drawn on top, the other series fade towards the background
(C<hover_fade> of the way, default 0.7), and the series' legend entry is
shown in bold. In pie, donut and polar area charts the same happens to
slices, and a donut shows the slice's share in its hole. Thin lines can
be hit from a cell next to them.

Each time the pointer moves onto something else, the chart fires a
C<SeriesHover> event (L<Term::Fabulous::Event::SeriesHover>) with the
series, the data point and its value: charts have no tooltips, so this
is how a program shows details, for example in a status line.

When the program removes or hides the series (or slice) the pointer is
on, the hover ends as if the pointer had moved off it: nothing is
faded, C<hovered> returns C<undef> and the chart fires a C<SeriesHover>
event without a series.

C<highlight> emphasizes a series from the program the same way, for
example the one selected in a list; the pointer wins while it is on a
series. C<< hover =E<gt> 0 >> turns hover effects and events off;
C<highlight> still works.

The chart listens to C<Mouse> and C<MouseMove> events itself to find
what the pointer is on, and lets them bubble on, so listeners of your
own on the chart and its ancestors still get them.

=head1 CONSTRUCTOR

=head2 new

All parameters are optional. Besides those of
L<Term::Fabulous::Widget::Box>, every chart takes:

=over

=item C<title>

A character string, or C<undef> (the default) for none. See
L</Title and legend>.

=item C<title_align>

C<left> (the default), C<center> or C<right>.

=item C<legend>

C<auto> (the default), C<top>, C<bottom>, C<left>, C<right> or C<none>.

=item C<palette>

A palette name (C<default>, the default, C<classic>, C<pastel> or
C<vivid>; see L<Term::Fabulous::Chart::Palette>) or a non-empty array
reference of colors in any format a canvas cell takes
(L<Term::Fabulous::Widget::Canvas/Colors>).

=item C<theme>

C<auto> (the default), C<dark> or C<light>: whether the chart's text
and lines are light (for a dark background) or dark (for a light one),
and which steps of the palette it uses. C<auto> picks C<light> when the
background is light; see L</Colors and themes>.

=item C<title_color>, C<text_color>, C<label_color>, C<axis_color>, C<grid_color>

Colors for the title, the legend text, the tick labels and axis titles,
the axis lines and the grid lines, in any format a canvas cell takes.
Default: C<undef>, mixed from the background and the theme's ink (see
L</Colors and themes>).

=item C<hover>

True (the default) for hover effects and C<SeriesHover> events.

=item C<hover_fade>

How far other series fade while one is emphasized: a number from 0
(not at all) to 1 (into the background). Default: 0.7.

=item C<highlight>

The name of a series (or the label of a slice) to emphasize, or C<undef>
(the default).

=back

An invalid value dies with a message that names the parameter, for
example C<Term::Fabulous::Widget::LineChart: legend must be auto,
bottom, left, none, right, top, got 'center'>.

=head1 METHODS

Every parameter has an accessor of the same name: without an argument it
returns the value, with one it checks and sets it (an invalid value dies
and changes nothing), and the chart shows the change in the next frame.

	$chart->title('Requests per minute');
	$chart->legend('bottom');
	$chart->palette( [ '#61afef', '#e06c75' ] );
	$chart->label_color(undef);    # back to the color mixed from the background
	$chart->highlight(undef);      # nothing emphasized

The color accessors return packed C<0xRRGGBB> integers, C<undef> for the
derived default; C<palette> returns the name or a copy of the array of
colors (packed integers). C<< hover(0) >> also ends a hover in progress:
the chart fires a C<SeriesHover> event without a series.

=head2 hovered

	my $what = $chart->hovered;    # { series => 'api', index => 3, label => 'Apr', value => 42 } or undef

What the mouse pointer is on, with the values the last C<SeriesHover>
event had.

=head2 effective_background

The background the chart is drawn on, as a packed C<0xRRGGBB> integer:
L<Term::Fabulous::Widget/background_below>, so its own, its nearest
ancestor's with an opaque one or the screen color of the theme;
C<undef> where there is none (in a L<Term::Fabulous::Static>, or under
a theme whose C<background> token has alpha 0). The ink is then mixed
from a fixed dark surface.

=head1 EVENTS

=over

=item C<SeriesHover> (L<Term::Fabulous::Event::SeriesHover>)

The pointer moved onto another series, point, slice or legend entry, or
off them.

=item C<CanvasResize>, C<Mouse>, C<MouseMove>

As for every canvas. A chart draws itself again after a resize; you need
not listen.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, and
every parameter of this page: C<title>, C<title_align>, C<legend>,
C<theme>, C<hover> (C<#true> or C<#false>), C<hover_fade>,
C<highlight>, the color properties C<title_color>, C<text_color>,
C<label_color>, C<axis_color> and C<grid_color>, and C<palette> with a
palette name or one or more colors:

=for highlighter language=kdl

	use Term::Fabulous::Widget::LineChart as LineChart

	LineChart "load" {
		title "System load"
		title_align "center"
		legend "bottom"
		theme "dark"
		palette "#61afef" "#e06c75" "#98c379"
		label_color "#8b93a7"
		grid_color "#2a2f3a"
		hover #true
		hover_fade 0.5
		highlight "web"
	}

C<palette "vivid"> names a palette. The series and data of a chart are
properties of the chart class; see
L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>,
L<Term::Fabulous::Widget::PieChart/KDL PROPERTIES> and
L<Term::Fabulous::Widget::RadarChart/KDL PROPERTIES>.

=head1 SUBCLASS INTERFACE

A chart of your own subclasses this class and provides three methods.
The chart calls them while it draws a frame, with a C<$look> hash of the
frame's colors: C<background> (the effective background or C<undef>),
C<base> (the color fills are blended with), C<mode> (C<dark> or
C<light>), C<title>, C<text>, C<label>, C<axis>, C<grid>, C<palette> (the
palette's colors), C<emphasis> (the series emphasized, or C<undef>) and
C<fade>.

=over

=item C<legend_entries($look)>

The legend's entries, as hashes: C<series> (the name hover reports),
C<label>, C<color>, C<symbol> (C<line>, C<fill> or C<point>), and
optionally C<glyph> (for points), C<value> (text shown right of the
label), C<raw_value> and C<index>.

=item C<default_legend_position>

C<top>, C<bottom>, C<left> or C<right>: where C<auto> puts the legend.

=item C<draw_plot( $surface, $x, $y, $width, $height, $look )>

Draws the plot into the area of a L<Term::Fabulous::Chart::Surface>.
Returns the number of rows it used from the top of the area, or nothing
when it used all of them: a legend at the bottom follows the used rows.

=back

Helpers: C<< slot_color( $look, $slot ) >> (the palette's color for a
slot), C<< shown_color( $look, $series, $rgb ) >> (faded unless the series
is emphasized), C<< is_emphasized( $look, $series ) >> and
C<< register_target( series => ..., index => ..., label => ..., value
=> ..., x => ... ) >>, which returns an owner id to record in the
surface's owner maps, so the pointer finds what was drawn there.

A chart whose program can take series or slices away calls
C<< end_hover_unless_shown(@names) >> after it did, with the names
(the C<series> of the targets) of everything still shown: when the
pointer is on something that is not among them, the hover ends as
described in L</Hover and emphasis>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Charts/CHARTS> (the guide),
L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::PieChart>,
L<Term::Fabulous::Widget::RadarChart>, L<Term::Fabulous::Chart::Palette>,
L<Term::Fabulous::Event::SeriesHover>,
L<Term::Fabulous::Cookbook::Charts>, L<Term::Fabulous::Cookbook::ChartTechniques>,
L<Term::Fabulous::Cookbook::ChartStyles>,
the example program F<examples/widgets/chart.pl>.

=cut
