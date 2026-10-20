package Term::Fabulous::Widget::Table::Borders;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(resolve_borders);

use List::Util qw(any first);
use Scalar::Util qw(refaddr);
use Term::Fabulous::Enum::BorderStyle;

my $HIDDEN = Term::Fabulous::Enum::BorderStyle->Hidden;
my $BLANK  = Term::Fabulous::Enum::BorderStyle->Blank;

sub _is_line ($style) {
	return defined $style && refaddr($style) != refaddr($HIDDEN) ? 1 : 0;
}

# Whether a style has joint glyphs, so that its lines join with others.
sub _joins ($style) {
	return defined $style->joints ? 1 : 0;
}

# Whether a frame side is drawn on the background outside the table
# (see Term::Fabulous::Role::HasBorderStyle/outer_border_sides). Line
# styles are, so that highlights stop at the frame. Block styles (Outer,
# Inner, Thick, ...) keep the backgrounds their glyphs are made for: a
# side whose glyph sits on the cell's own background stays inside, so the
# cells' colors reach the frame; one whose glyph sits on the background
# beside the box (location 1 or 2) is outside, and so are the cells of
# other lines that end on it.
sub _drawn_outside ( $style, $side ) {
	return 1 if _joins($style);
	my $location
		= $side eq 'top'    ? ( $style->get_top_locations )[1]
		: $side eq 'bottom' ? ( $style->get_bottom_locations )[1]
		: $side eq 'left'   ? $style->get_left_locations
		:                     $style->get_right_locations;
	return $location == 1 || $location == 2 ? 1 : 0;
}

# The first style the levels name, from the most specific: a level is an
# array of candidates, the last one winning within the level (the cell
# below, or to the right). Hidden ends the search: there is no line.
sub _first_style (@levels) {
	foreach my $level (@levels) {
		my $style = first { defined } reverse @$level;
		return _is_line($style) ? $style : undef if defined $style;
	}
	return undef;
}

# Works out the lines of a table. Takes
#   columns => the number of grid columns
#   header  => how many of the lines are header lines (they come first)
#   gutter  => whether a scrollbar column follows the last grid column
#   table   => { border_top, border_right, border_bottom, border_left,
#                column_lines, row_lines, header_line }
#   column_styles => [ per column { border_left, border_right, row_lines } ]
#   lines   => [ per line { spanning, ledge, style => { border_top,
#                border_right, border_bottom, border_left, column_lines },
#                cells => [ per cell { border_top, border_right,
#                border_bottom, border_left } ] } ]  (a spanning line has
#                one cell; a ledge is the first or the last line, holds
#                nothing and has no line between itself and its neighbour,
#                so it draws the frame's top or bottom and nothing else)
# and returns { lines => per line, per cell { sides => { top, right,
# bottom, left } (a BorderStyle per drawn side, Blank where a line passes
# elsewhere but not here), corners => { top_left, ... } (the glyph of
# every drawn corner that does not keep the glyph of its style), outer =>
# [ the frame sides drawn outside ] }, gutter => the same for the strips
# of the scrollbar column, { header, body, footer }, or undef }.
sub resolve_borders (%args) {
	my ( $columns, $lines ) = @args{qw(columns lines)};
	my $header_lines = $args{header}        // 0;
	my $gutter       = $args{gutter}        // 0;
	my $table        = $args{table}         // {};
	my $column_style = $args{column_styles} // [];
	my $last_line    = $#$lines;
	my $line_count   = scalar @$lines;

	my @ledges = grep { $lines->[$_]{ledge} } 0 .. $last_line;
	die "Term::Fabulous::Widget::Table::Borders: a ledge must be the first or the last line" if grep { $_ != 0 && $_ != $last_line } @ledges;

	my $cell_style = sub ( $line, $column ) {
		my $cells = $lines->[$line]{cells} // [];
		return ( $lines->[$line]{spanning} ? $cells->[0] : $cells->[$column] ) // {};
	};
	my $row_style = sub ($line) { $lines->[$line]{style} // {} };
	my $is_ledge  = sub ($line) { $line >= 0 && $line < $line_count && $lines->[$line]{ledge} ? 1 : 0 };

	# The horizontal segment above line $boundary ($line_count: below the
	# last line) in a column ($columns: in the scrollbar column, which has
	# no cells and no column style).
	my $horizontal = sub ( $boundary, $column ) {
		my ( $above, $below ) = ( $boundary - 1, $boundary );
		my $inner = $boundary > 0 && $boundary < $line_count;
		return undef if $inner && ( $is_ledge->($above) || $is_ledge->($below) );
		my @cells   = ( ( $above >= 0 ? $cell_style->( $above, $column )->{border_bottom} : undef ), ( $below < $line_count ? $cell_style->( $below, $column )->{border_top} : undef ) );
		my @rows    = ( ( $above >= 0 ? $row_style->($above)->{border_bottom}             : undef ), ( $below < $line_count ? $row_style->($below)->{border_top}             : undef ) );
		my @columns = $inner && $boundary != $header_lines ? ( ( $column_style->[$column] // {} )->{row_lines} ) : ();
		my $table_line
			= $boundary == 0             ? $table->{border_top}
			: $boundary == $line_count   ? $table->{border_bottom}
			: $boundary == $header_lines ? $table->{header_line} // $table->{row_lines}
			:                              $table->{row_lines};
		return _first_style( \@cells, \@rows, \@columns, [$table_line] );
	};

	# The vertical segment of a line left of grid column $boundary
	# ($columns: right of the last column, which is no line when the
	# scrollbar column follows; the strips draw the frame there).
	my $vertical = sub ( $line, $boundary ) {
		return undef if $gutter && $boundary == $columns;
		my $spanning = $lines->[$line]{spanning};
		my $outer    = $boundary == 0 || $boundary == $columns;
		return undef if $spanning && !$outer;
		my @cells = (
			( $boundary > 0        ? $cell_style->( $line, $boundary - 1 )->{border_right} : undef ),
			( $boundary < $columns ? $cell_style->( $line, $boundary )->{border_left}      : undef ),
		);
		my $row = $row_style->($line);
		my @rows
			= $boundary == 0        ? ( $row->{border_left} )
			: $boundary == $columns ? ( $row->{border_right} )
			:                         ( $row->{column_lines} );
		my @column_levels = (
			( $boundary > 0        ? ( $column_style->[ $boundary - 1 ] // {} )->{border_right} : undef ),
			( $boundary < $columns ? ( $column_style->[$boundary]       // {} )->{border_left}  : undef ),
		);
		my $table_line = $boundary == 0 ? $table->{border_left} : $boundary == $columns ? $table->{border_right} : $table->{column_lines};
		return _first_style( \@cells, \@rows, \@column_levels, [$table_line] );
	};

	my ( @h, @v, @h_gutter );
	foreach my $boundary ( 0 .. $line_count ) {
		$h[$boundary]        = [ map { $horizontal->( $boundary, $_ ) } 0 .. $columns - 1 ];
		$h_gutter[$boundary] = $gutter ? $horizontal->( $boundary, $columns ) : undef;
	}
	foreach my $line ( 0 .. $last_line ) {
		$v[$line] = [ map { $vertical->( $line, $_ ) } 0 .. $columns ];
	}
	my @row_line_exists = map {
		my $boundary = $_;
		( any { defined } @{ $h[$boundary] }, $h_gutter[$boundary] ) ? 1 : 0
	} 0 .. $line_count;
	my @column_line_exists = map {
		my $boundary = $_;
		( any { defined $v[$_][$boundary] } 0 .. $last_line ) ? 1 : 0
	} 0 .. $columns;

	# Who draws a horizontal boundary: the line below it, except that a
	# boundary above a spanning line is drawn by the (non-spanning) line
	# above it, the last boundary by the last line, and the boundary below
	# the header by the header, which does not scroll.
	my $drawn_as_bottom = sub ($boundary) {
		return 1 if $boundary == $line_count;
		return 0 if $boundary == 0;
		return 1 if $boundary == $header_lines;
		return $lines->[$boundary]{spanning} && !$lines->[ $boundary - 1 ]{spanning} ? 1 : 0;
	};

	my $vertical_arm = sub ( $line, $boundary ) {
		return undef if $line < 0 || $line > $last_line;
		return $v[$line][$boundary];
	};
	my $horizontal_arm = sub ( $boundary, $column ) {
		return undef if $column < 0 || $column >= $columns;
		return $h[$boundary][$column];
	};

	# The glyph of a point of the outer frame when the frame's style has no
	# joints (Outer, Inner, Thick, ...): the frame runs on with its straight
	# edge glyph where an inner line meets it, and keeps its own corner
	# glyphs at the table's corners (undef: no glyph of the table's own).
	# Returns ( 1, $glyph ) for such a point, () for any other.
	my $frame_point = sub ( $boundary, $grid_line, $arms ) {
		my $on_top    = $boundary == 0;
		my $on_bottom = $boundary == $line_count;
		my $on_side   = $grid_line == 0 || $grid_line == $columns;
		my $edge
			= $on_top || $on_bottom ? $arms->{left} // $arms->{right}
			: $on_side              ? $arms->{up} // $arms->{down}
			:                         undef;
		return () unless defined $edge && !_joins($edge);
		return ( 1, undef ) if ( $on_top || $on_bottom ) && $on_side;
		return ( 1, ( $edge->get_top_glyphs )[1] ) if $on_top;
		return ( 1, ( $edge->get_bottom_glyphs )[1] ) if $on_bottom;
		return ( 1, ( $grid_line == 0 ? $edge->get_left_glyphs : $edge->get_right_glyphs ) );
	};
	my $corner = sub ( $boundary, $grid_line ) {
		my %arms = (
			up    => $vertical_arm->( $boundary - 1, $grid_line ),
			down  => $vertical_arm->( $boundary,     $grid_line ),
			left  => $horizontal_arm->( $boundary, $grid_line - 1 ),
			right => $horizontal_arm->( $boundary, $grid_line ),
		);
		my ( $on_frame, $frame_glyph ) = $frame_point->( $boundary, $grid_line, \%arms );
		return $frame_glyph if $on_frame;
		return Term::Fabulous::Enum::BorderStyle->junction(%arms) // ' ';
	};
	my $side_style = sub ( $exists, $style ) {
		return undef unless $exists;
		return $style // $BLANK;
	};

	# The strips of the scrollbar column, beside the header lines, the
	# body and the last line: each draws the frame's right side, in the
	# table's style, and the horizontal lines that run on beside it (the
	# top and the line below the header, the bottom). The side the body
	# strip shares with the header and footer strips is one unbroken
	# line, so its ends are arms of their corners.
	my $strips = sub () {
		my $right  = _first_style( [ $table->{border_right} ] );
		my $side   = sub ($boundary) { $side_style->( $row_line_exists[$boundary], $h_gutter[$boundary] ) };
		my $corner = sub ( $boundary, %arms ) {
			my ( $on_frame, $frame_glyph ) = $frame_point->( $boundary, $columns, \%arms );
			return $frame_glyph if $on_frame;
			return Term::Fabulous::Enum::BorderStyle->junction(%arms) // ' ';
		};
		my $strip = sub ( $sides, $corners, @frame_sides ) {
			my %drawn   = map  { $_ => $sides->{$_} } grep   { defined $sides->{$_} } keys %$sides;
			my %corners = map  { $_ => $corners->{$_} } grep { defined $corners->{$_} } keys %$corners;
			my @outer   = grep { defined $drawn{$_} && _drawn_outside( $drawn{$_}, $_ ) } @frame_sides;
			return { sides => \%drawn, corners => \%corners, outer => \@outer };
		};
		my %header = ( top    => $side->(0), bottom => ( $header_lines ? $side->($header_lines) : undef ), right => $right );
		my %footer = ( bottom => $side->($line_count), right => $right );
		return {
			header => $strip->(
				\%header,
				{
					top_right => ( $header{top} && $header{right} ? $corner->( 0, left => $h_gutter[0], down => $right ) : undef ),
					bottom_right => ( $header{bottom} && $header{right} ? $corner->( $header_lines, left => $h_gutter[$header_lines], up => $right, down => $right ) : undef ),
				},
				qw(top right)
			),
			body   => $strip->( { right => $right }, {}, qw(right) ),
			footer =>
				$strip->( \%footer, { bottom_right => ( $footer{bottom} && $footer{right} ? $corner->( $line_count, left => $h_gutter[$line_count], up => $right ) : undef ) }, qw(bottom right) ),
		};
	};

	my @result;
	foreach my $line ( 0 .. $last_line ) {
		my $spanning     = $lines->[$line]{spanning};
		my @cell_columns = $spanning ? ( [ 0, $columns - 1 ] ) : map { [ $_, $_ ] } 0 .. $columns - 1;
		my $top_drawn    = $row_line_exists[$line]       && !$drawn_as_bottom->($line);
		my $bottom_drawn = $row_line_exists[ $line + 1 ] && $drawn_as_bottom->( $line + 1 );
		my @cells;
		foreach my $span (@cell_columns) {
			my ( $first, $last ) = @$span;
			my %sides = (
				left   => $side_style->( $column_line_exists[$first], $v[$line][$first] ),
				right  => ( $last == $columns - 1 ? $side_style->( $column_line_exists[$columns], $v[$line][$columns] )                                       : undef ),
				top    => ( $top_drawn            ? $side_style->( 1,                             first { defined } @{ $h[$line] }[ $first .. $last ] )       : undef ),
				bottom => ( $bottom_drawn         ? $side_style->( 1,                             first { defined } @{ $h[ $line + 1 ] }[ $first .. $last ] ) : undef ),
			);
			my %corners;
			$corners{top_left}     = $corner->( $line,     $first ) if $sides{top}      && $sides{left};
			$corners{top_right}    = $corner->( $line,     $columns ) if $sides{top}    && $sides{right};
			$corners{bottom_left}  = $corner->( $line + 1, $first ) if $sides{bottom}   && $sides{left};
			$corners{bottom_right} = $corner->( $line + 1, $columns ) if $sides{bottom} && $sides{right};
			delete @corners{ grep { !defined $corners{$_} } keys %corners };
			my %on_frame = (
				left   => $first == 0,
				right  => $last == $columns - 1,
				top    => $line == 0,
				bottom => $line == $last_line,
			);
			my @outer = grep { defined $sides{$_} && $on_frame{$_} && _drawn_outside( $sides{$_}, $_ ) } qw(left right top bottom);
			push @cells, { sides => { map { $_ => $sides{$_} } grep { defined $sides{$_} } keys %sides }, corners => \%corners, outer => \@outer };
		}
		push @result, \@cells;
	}
	return { lines => \@result, gutter => $gutter ? $strips->() : undef };
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Borders - Work out the grid lines of a table

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table::Borders qw(resolve_borders);
	use Term::Fabulous::Enum::BorderStyle;
	my $Solid = Term::Fabulous::Enum::BorderStyle->Solid;

	my $resolved = resolve_borders(
		columns => 2,
		header  => 1,
		table   => { map( { $_ => $Solid } qw(border_top border_right border_bottom border_left column_lines) ) },
		lines   => [ {}, {}, { spanning => 1 }, {} ],
	);
	my $first = $resolved->{lines}[0][0];    # { sides => { top, left }, corners => { top_left => "\x{250C}" } }

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> draws its lines with the borders of its
cells: every line between two cells is drawn by exactly one of them, and
the corners where lines meet get the junction glyphs of
L<Term::Fabulous::Enum::BorderStyle/junction>. This module decides, from
the styles of the table, its columns, its lines (rows) and its cells,
which cell draws which side in which style and which glyph each drawn
corner gets. It has no widgets; the table applies the result. You do
not need it unless you draw a grid of your own; the lines of a table
are explained in
L<Term::Fabulous::Manual::TableStyles/Lines between and around the cells>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/cookbook-table-line-styles.svg" alt="Nine small tables with different lines: the default round frame, a full grid, no lines, a double frame with a heavy title line, a heavy frame with dashed row lines, ASCII lines, and Outer, Inner and Thick block frames"></p>

=end html

=head2 Where a line is, and in which style

Every segment of a grid line (between two cells, or between a cell and
the outside) gets the first style named, from the most specific level
to the least: the cells on both sides (C<border_*>), the rows
(C<border_*>, and C<column_lines> between the cells of a row), the
columns (C<border_left>, C<border_right>, and C<row_lines> between the
cells of a column), the table (C<border_*>, C<column_lines>,
C<row_lines>, C<header_line> below the header). Within a level, the
cell (or row) below or to the right wins. The style C<Hidden> (C<'none'>
in a style hash) means "no line" and ends the search.

A grid line exists when any of its segments has a style. Where it exists
but a segment has none, the cell still takes the cell of space and
draws it blank, so the contents of every row and column stay aligned.
Spanning lines (group headers) have only their outer vertical
segments.

=head2 Who draws it

The cell to the right of a vertical segment draws it as its left side;
the last column also draws the right edge. The line below a horizontal
segment draws it as its top side, except: the last line draws the
bottom edge, the header draws the line below it (the body scrolls under
the header), and a non-spanning line draws the line below it when the
next line spans the columns, so that the junctions of its columns are
part of its own corners.

A I<ledge> is a line that holds nothing and draws only an edge of the
frame: the table's footer, which draws the bottom edge below the
scrolling rows, and its top without column titles. A ledge is the
first or the last line (any other dies), and there is no line between
it and its neighbour, whatever the styles say.

=head2 The scrollbar column

With C<gutter>, a column for the scrollbar follows the last grid
column. The cells of the last column then draw no right side: the
frame's right side, in the table's C<border_right>, is drawn by three
I<strips> beside the header lines, the body and the last line, which
the result returns under C<gutter>. The horizontal lines that reach the
frame run on beside the strips: the header strip draws the top edge
and the line below the header lines, the footer strip the bottom edge,
each with the corner or junction where it meets the right side. Lines
between rows end at the last cell.

=head2 A frame in a block style

A frame side in a style without joint glyphs (C<Outer>, C<Inner>,
C<Thick>, ...) does not join: where an inner line meets it, the frame
runs on with its straight edge glyph and the inner line ends there; at
the table's four corners, the frame keeps the corner glyphs of its
style (the corner is not in C<corners>, so the side's style draws it).
Such a side is listed in C<outer> only when its style draws that side
on the background outside the box (glyph location 1 or 2, as
C<Inner>), so that the cells' colors reach the glyphs of C<Outer> and
C<Thick>. Frame sides in line styles are always in C<outer>.

=head1 FUNCTIONS

=head2 resolve_borders

	my $resolved = resolve_borders(%arguments);
	my $cells    = $resolved->{lines};
	my $strips   = $resolved->{gutter};

Arguments: C<columns> (the number of grid columns), C<header> (how many
of the lines are header lines, default 0), C<gutter> (whether the
scrollbar column follows the last grid column, default 0), C<table>,
C<column_styles> (one hash per column) and C<lines> (one hash per
line, header lines first, each with C<spanning>, C<ledge>, C<style>
and C<cells>, one hash per cell or one for a spanning line), with the
keys named above. Every hash and key is optional; styles are
L<Term::Fabulous::Enum::BorderStyle> items.

Returns a hash reference. C<lines> is an array reference with one
entry per line, an array reference with one hash per cell: C<sides>
maps each side the cell draws (C<top>, C<right>, C<bottom>, C<left>)
to its style (C<Blank> for a segment without a line on a line that
exists), C<corners> maps each corner the cell draws (C<top_left>,
C<top_right>, C<bottom_left>, C<bottom_right>; a corner is drawn where
two drawn sides meet) to its glyph (a space where no line passes; a
corner of a block-style frame is left out, see L</A frame in a block
style>), and C<outer> lists the drawn sides of the outer frame of the
table that are drawn on the background outside it (for
L<Term::Fabulous::Role::HasBorderStyle/outer_border_sides>). C<gutter>
is C<undef> without the C<gutter> argument; with it, a hash with the
keys C<header>, C<body> and C<footer>, one for each strip of the
scrollbar column (see L</The scrollbar column>), each a hash like a
cell's (C<sides>, C<corners>, C<outer>).

=head1 SEE ALSO

L<Term::Fabulous::Manual::TableStyles/STYLES AND BORDERS>,
L<Term::Fabulous::Manual::TableStyles/Lines of columns, rows and cells>,
L<Term::Fabulous::Enum::BorderStyle/junction>.

=cut
