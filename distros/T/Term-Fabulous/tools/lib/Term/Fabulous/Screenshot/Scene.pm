package Term::Fabulous::Screenshot::Scene;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class Term::Fabulous::Screenshot::Scene :strict(params) {
	use Carp qw(croak);
	use Term::Fabulous::Screenshot::BoxDrawing qw(is_drawn_glyph glyph_shapes);

	# Characters every monospace font has, one cell wide: text of these is
	# drawn in runs. Anything else (symbols, CJK, emoji, clusters with
	# combining marks) is drawn one cell at a time, centered in its cells,
	# so a fallback font with other widths cannot shift the line.
	use constant RUN_CHARACTER => qr/\A[\x21-\x7E\xA1-\x{17F}\x{370}-\x{3FF}\x{400}-\x{4FF}]\z/;

	use constant DIM_FACTOR => 0.5;    # how far dim text moves towards the background

	# The width of a title character in units of the title's font size (a
	# monospace font), and the room kept free between buttons and title.
	use constant TITLE_CHARACTER_WIDTH => 0.6;
	use constant TITLE_BUTTON_GAP      => 12;

	field $screen :param :reader;
	field $theme  :param :reader;
	field $title  :param :reader = '';
	field $scale  :param :reader = 1;    # image units per theme unit

	# The parts of the picture, in image units, back to front.
	field $layout      :reader;
	field $shown_title :reader;    # the title as it fits between the window buttons
	field @backgrounds :reader;    # { x, y, width, height, color }
	field @shapes      :reader;    # { type => 'rect', x, y, width, height, color }, { type => 'polyline', points, width, color } or { type => 'circle', cx, cy, r, color }
	field @texts       :reader;    # { x, y, width, glyphs => [ [ x, glyph ] ], text, color, bold, italic, anchor }
	field @lines       :reader;    # decorations (underline, strikeout, overline): { x, y, width, height, color }
	field @pictures    :reader;    # sixel pictures over all of these: { x, y, width, height, png }

	ADJUST {
		croak "Term::Fabulous::Screenshot::Scene: the scale must be a positive whole number, got '$scale'" unless $scale =~ /\A[1-9][0-9]*\z/;
		$layout = { %{ $theme->layout( $screen->columns, $screen->rows ) } };
		$layout->{$_} *= $scale foreach keys %$layout;
		$shown_title = $self->_fitting_title;

		foreach my $y ( 0 .. $screen->rows - 1 ) {
			my @cells = map { $self->_resolve($_) } $screen->row($y);
			push @backgrounds, $self->_background_runs( $y, \@cells );
			push @shapes,      $self->_cell_shapes( $y, $_ ) foreach grep { is_drawn_glyph( $_->{glyph} ) } @cells;
			push @texts,       $self->_text_runs( $y, \@cells );
			push @lines,       $self->_decorations( $y, $_ ) foreach @cells;
		}
		@backgrounds = _merge_rects(@backgrounds);
		@shapes      = ( _merge_rects( grep { $_->{type} eq 'rect' } @shapes ), grep { $_->{type} ne 'rect' } @shapes );
		@lines       = _merge_rects(@lines);
		@pictures    = map { $self->_picture($_) } $screen->pictures;
	}

	# The title, shortened with '...' when it is wider than the room the
	# window buttons leave; the same room is kept free on the right, so a
	# centered title stays centered.
	method _fitting_title () {
		my $reserved = ( @{ $theme->button_colors } * $theme->button_spacing + $theme->button_radius + TITLE_BUTTON_GAP ) * $scale;
		my $room     = $layout->{window_width} - 2 * $reserved;
		my $fitting  = int( $room / ( $theme->title_font_size * $scale * TITLE_CHARACTER_WIDTH ) );
		return $title if length($title) <= $fitting;
		return '' if $fitting < 4;
		return substr( $title, 0, $fitting - 3 ) . '...';
	}

	method cell_width ()  { return $theme->cell_width * $scale }
	method cell_height () { return $theme->cell_height * $scale }
	method font_size ()   { return $theme->font_size * $scale }

	# The final colors of a cell: defaults filled in, reverse video applied,
	# dim text mixed towards the background (half opaque), invisible text
	# dropped. Blink has no picture; it is ignored.
	method _resolve ($cell) {
		my $styles = $cell->{styles};
		my $fg     = $cell->{fg} // $theme->default_foreground;
		my $bg     = $cell->{bg} // $theme->default_background;
		( $fg, $bg ) = ( $bg, $fg ) if $styles->{reverse};
		$fg = mix_colors( $bg, $fg, 1 - DIM_FACTOR ) if $styles->{dim};
		my $glyph = $styles->{invisible} ? ' ' : $cell->{glyph};
		return { %$cell, glyph => $glyph, fg => $fg, bg => $bg };
	}

	method _cell_x ($column) { return $layout->{terminal_x} + $column * $self->cell_width }
	method _cell_y ($row)    { return $layout->{terminal_y} + $row * $self->cell_height }

	# Background rectangles for every run of cells with the same color, except
	# the terminal's default background, which the window already shows.
	method _background_runs ( $y, $cells ) {
		my @runs;
		foreach my $cell (@$cells) {
			next if $cell->{bg} == $theme->default_background;
			my $x     = $self->_cell_x( $cell->{x} );
			my $width = $cell->{columns} * $self->cell_width;
			if ( @runs && $runs[-1]{color} == $cell->{bg} && $runs[-1]{x} + $runs[-1]{width} == $x ) {
				$runs[-1]{width} += $width;
				next;
			}
			push @runs, { x => $x, y => $self->_cell_y($y), width => $width, height => $self->cell_height, color => $cell->{bg} };
		}
		return @runs;
	}

	method _cell_shapes ( $y, $cell ) {
		my ( $left, $top ) = ( $self->_cell_x( $cell->{x} ), $self->_cell_y($y) );
		my @cell_shapes = glyph_shapes( $cell->{glyph}, $self->cell_width, $self->cell_height, $theme->line_thickness * $scale );
		return map { _placed_shape( $_, $left, $top, $cell ) } @cell_shapes;
	}

	sub _placed_shape ( $shape, $left, $top, $cell ) {
		if ( $shape->{type} eq 'rect' ) {
			return {
				type   => 'rect',
				x      => $left + $shape->{x},
				y      => $top + $shape->{y},
				width  => $shape->{width},
				height => $shape->{height},
				color  => mix_colors( $cell->{bg}, $cell->{fg}, $shape->{coverage} ),
			};
		}
		if ( $shape->{type} eq 'circle' ) {
			return { type => 'circle', cx => $left + $shape->{cx}, cy => $top + $shape->{cy}, r => $shape->{r}, color => $cell->{fg} };
		}
		my @points = @{ $shape->{points} };
		$points[$_] += $_ % 2 ? $top : $left foreach 0 .. $#points;
		return { type => 'polyline', points => \@points, width => $shape->{width}, color => $cell->{fg} };
	}

	# Text in runs of cells with the same color and weight, spaces included
	# between them; other glyphs one per run, centered in their cells.
	method _text_runs ( $y, $cells ) {
		my $baseline = $self->_cell_y($y) + $theme->baseline * $scale;
		my ( @runs, $open );
		foreach my $cell (@$cells) {
			my $glyph = $cell->{glyph};
			if ( is_drawn_glyph($glyph) ) {
				undef $open;    # a run cannot skip a cell
				next;
			}
			my $style = join ',', $cell->{fg}, $cell->{styles}{bold} ? 1 : 0, $cell->{styles}{italic} ? 1 : 0;
			my $x     = $self->_cell_x( $cell->{x} );

			if ( $glyph eq ' ' ) {
				push @{ $open->{pending_spaces} }, $x if $open;
				next;
			}
			if ( $glyph !~ RUN_CHARACTER ) {
				undef $open;
				push @runs, $self->_run( $cell, $x, $baseline, 'middle' );
				next;
			}
			if ( $open && $open->{style} eq $style ) {
				push @{ $open->{glyphs} }, map { [ $_, ' ' ] } @{ delete $open->{pending_spaces} // [] };
				push @{ $open->{glyphs} }, [ $x, $glyph ];
				$open->{width} = $x + $self->cell_width - $open->{x};
				next;
			}
			$open = $self->_run( $cell, $x, $baseline, 'start' );
			$open->{style} = $style;
			push @runs, $open;
		}
		foreach my $run (@runs) {
			delete @$run{qw(style pending_spaces)};
			$run->{text} = join '', map { $_->[1] } @{ $run->{glyphs} };
		}
		return @runs;
	}

	method _run ( $cell, $x, $baseline, $anchor ) {
		return {
			x      => $x,
			y      => $baseline,
			width  => $cell->{columns} * $self->cell_width,
			glyphs => [ [ $x, $cell->{glyph} ] ],
			color  => $cell->{fg},
			bold   => $cell->{styles}{bold}   ? 1 : 0,
			italic => $cell->{styles}{italic} ? 1 : 0,
			anchor => $anchor,
		};
	}

	method _decorations ( $y, $cell ) {
		my $styles = $cell->{styles};
		my ( $left, $top ) = ( $self->_cell_x( $cell->{x} ), $self->_cell_y($y) );
		my $width     = $cell->{columns} * $self->cell_width;
		my $thickness = $theme->line_thickness * $scale;
		my $underline = $top + ( $theme->baseline + 1 ) * $scale;    # a second line fits below it in the cell

		my @offsets;
		push @offsets, $underline if $styles->{underline} || $styles->{double_underline};
		push @offsets, $underline + 2 * $thickness if $styles->{double_underline};
		push @offsets, $top + int( $self->cell_height * 0.55 ) if $styles->{strikeout};
		push @offsets, $top if $styles->{overline};
		return map { { x => $left, y => $_, width => $width, height => $thickness, color => $cell->{fg} } } @offsets;
	}

	method _picture ($picture) {
		return {
			x      => $self->_cell_x( $picture->{x} ),
			y      => $self->_cell_y( $picture->{y} ),
			width  => $picture->{columns} * $self->cell_width,
			height => $picture->{rows} * $self->cell_height,
			png    => $picture->{png},
		};
	}

	# Joins rectangles of one color that continue each other, first along
	# rows, then down columns; the picture stays the same with fewer shapes.
	sub _merge_rects (@rects) {
		my @merged = _merge_along( \@rects, 'x', 'width', 'y', 'height' );
		return _merge_along( \@merged, 'y', 'height', 'x', 'width' );
	}

	sub _merge_along ( $rects, $position, $length, $cross_position, $cross_length ) {
		my %group;
		foreach my $rect (@$rects) {
			my $key = join ',', $rect->{color}, $rect->{$cross_position}, $rect->{$cross_length};
			push @{ $group{$key} }, $rect;
		}
		my @result;
		foreach my $key ( sort keys %group ) {
			my @sorted = sort { $a->{$position} <=> $b->{$position} } @{ $group{$key} };
			my @joined = ( { %{ shift @sorted } } );
			foreach my $rect (@sorted) {
				my $last = $joined[-1];
				if ( $rect->{$position} <= $last->{$position} + $last->{$length} ) {
					my $end = $rect->{$position} + $rect->{$length};
					$last->{$length} = $end - $last->{$position} if $end > $last->{$position} + $last->{$length};
					next;
				}
				push @joined, {%$rect};
			}
			push @result, @joined;
		}
		my @sorted = sort { $a->{y} <=> $b->{y} || $a->{x} <=> $b->{x} || $a->{color} <=> $b->{color} } @result;
		return @sorted;
	}

	# $over mixed over $under: 0 is $under, 1 is $over.
	sub mix_colors ( $under, $over, $amount ) {
		return $over if $amount >= 1;
		return $under if $amount <= 0;
		my $mixed = 0;
		foreach my $shift ( 16, 8, 0 ) {
			my ( $low, $high ) = ( ( $under >> $shift ) & 0xFF, ( $over >> $shift ) & 0xFF );
			$mixed |= int( $low + ( $high - $low ) * $amount + 0.5 ) << $shift;
		}
		return $mixed;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Scene - What a screenshot image shows, as
shapes and text

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Scene;

	my $scene = Term::Fabulous::Screenshot::Scene->new(
		screen => $screen,
		theme  => Term::Fabulous::Screenshot::Theme->new,
		title  => 'perl examples/form.pl',
		scale  => 2,
	);
	foreach my $rect ( $scene->backgrounds ) { ... }

=head1 DESCRIPTION

Maintainer tool, not installed. Turns a
L<Term::Fabulous::Screenshot::Screen> into everything an image of it
shows, in image coordinates, so that the SVG and the PNG renderer draw
the same picture and differ only in how they paint:

=over

=item *

the terminal's default colors filled in, reverse video applied, dim
text mixed half way towards its background (as if drawn at half
opacity), invisible text left out and blink ignored;

=item *

background rectangles, one per run of cells of the same color, except
where the terminal's default background shows;

=item *

box drawing and block element characters as rectangles and polylines,
Braille patterns as circles and sextants as rectangles
(L<Term::Fabulous::Screenshot::BoxDrawing>);

=item *

text: runs of characters every monospace font has, and every other
glyph on its own, centered in its cells;

=item *

underline, double underline, strikeout and overline as rectangles;

=item *

sixel pictures over everything else, each stretched to the cells it
covers.

=back

Rectangles of one color that continue each other are joined.

=head1 CONSTRUCTOR

=head2 new

=over

=item C<screen>

The L<Term::Fabulous::Screenshot::Screen> to show. Required.

=item C<theme>

A L<Term::Fabulous::Screenshot::Theme>. Required.

=item C<title>

The window title. Default: empty.

=item C<scale>

A positive whole number; every size of the theme is multiplied by it.
Default: 1.

=back

=head1 METHODS

=head2 shown_title

The title as the window shows it: shortened with C<...> at the end when
it is wider than the room between the window buttons and the same room
on the right, empty when not even a few characters fit.

=head2 layout

The theme's layout (see L<Term::Fabulous::Screenshot::Theme/layout>),
scaled.

=head2 backgrounds, shapes, texts, lines, pictures

The parts of the picture, back to front. Colors are C<0xRRGGBB>.
Backgrounds and lines are C<{ x, y, width, height, color }>. Shapes are
rectangles like those, with C<type =E<gt> 'rect'>, C<{ type =E<gt>
'polyline', points, width, color }> or C<{ type =E<gt> 'circle', cx, cy,
r, color }>. Texts are C<{ x, y, width, text,
glyphs, color, bold, italic, anchor }>: C<y> is the baseline, C<width>
the width of the cells the text covers, C<glyphs> the left edge of each
character's cell with the character, and C<anchor> C<start> for a run
or C<middle> for a single glyph centered in C<width>. Pictures are
C<{ x, y, width, height, png }>: the box of the cells a sixel picture
covers and the picture as PNG data, in the order the terminal drew
them.

=head2 cell_width, cell_height, font_size

The theme's sizes, scaled.

=head1 FUNCTIONS

=head2 mix_colors

	my $color = Term::Fabulous::Screenshot::Scene::mix_colors( $under, $over, $amount );

C<$over> mixed over C<$under>; C<$amount> 0 gives C<$under>, 1 gives
C<$over>.

=cut
