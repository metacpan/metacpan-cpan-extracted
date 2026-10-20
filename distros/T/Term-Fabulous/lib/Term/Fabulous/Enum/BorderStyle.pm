package Term::Fabulous::Enum::BorderStyle;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::PadX::Enum;

enum Term::Fabulous::Enum::BorderStyle {
	use List::Util qw(pairmap);
	use Scalar::Util qw(blessed);

	state $heavy_joints = [
		"\x{2501}",    # h_line
		"\x{2503}",    # v_line
		"\x{254B}",    # cross
		"\x{2533}",    # t_down
		"\x{253B}",    # t_up
		"\x{2523}",    # t_right
		"\x{252B}",    # t_left
	];
	state $solid_joints = [
		"\x{2500}",    # h_line
		"\x{2502}",    # v_line
		"\x{253C}",    # cross
		"\x{252C}",    # t_down
		"\x{2534}",    # t_up
		"\x{251C}",    # t_right
		"\x{2524}",    # t_left
	];

	item Ascii(
		glyphs    => [ '+', '-', '+', '|', '|', '+', '-', '+' ],
		locations => [ 0,   0,   0,   0,   0,   0,   0,   0 ],
		joints    => [ '-', '|', '+', '+', '+', '+', '+' ],
	);
	item Blank(
		glyphs    => [ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' ],
		locations => [ 0,   0,   0,   0,   0,   0,   0,   0 ],
	);
	item Block(
		glyphs    => [ "\x{2584}", "\x{2584}", "\x{2584}", "\x{2588}", "\x{2588}", "\x{2580}", "\x{2580}", "\x{2580}" ],
		locations => [ 1,          1,          1,          0,          0,          1,          1,          1 ],
	);
	item DarkShade(
		glyphs    => [ "\x{2593}", "\x{2593}", "\x{2593}", "\x{2593}", "\x{2593}", "\x{2593}", "\x{2593}", "\x{2593}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
	);
	item Dashed(
		glyphs    => [ "\x{250F}", "\x{254D}", "\x{2513}", "\x{254F}", "\x{254F}", "\x{2517}", "\x{254D}", "\x{251B}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
		joints    => $heavy_joints,
	);
	item Double(
		glyphs    => [ "\x{2554}", "\x{2550}", "\x{2557}", "\x{2551}", "\x{2551}", "\x{255A}", "\x{2550}", "\x{255D}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
		joints    => [
			"\x{2550}",    # h_line
			"\x{2551}",    # v_line
			"\x{256C}",    # cross
			"\x{2566}",    # t_down
			"\x{2569}",    # t_up
			"\x{2560}",    # t_right
			"\x{2563}",    # t_left
		],
		mixed_joints => sub {
			Term::Fabulous::Enum::BorderStyle->Solid, [
				"\x{256A}",    # cross   horizontal double, vertical single
				"\x{2564}",    # t_down  down single, horizontal double
				"\x{2567}",    # t_up    up single, horizontal double
				"\x{255E}",    # t_right vertical single, right double
				"\x{2561}",    # t_left  vertical single, left double
				],
				;
		},
	);
	item Heavy(
		glyphs       => [ "\x{250F}", "\x{2501}", "\x{2513}", "\x{2503}", "\x{2503}", "\x{2517}", "\x{2501}", "\x{251B}" ],
		locations    => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
		joints       => $heavy_joints,
		mixed_joints => sub {
			Term::Fabulous::Enum::BorderStyle->Solid, [
				"\x{253F}",    # cross   horizontal heavy, vertical light
				"\x{252F}",    # t_down  down light, horizontal heavy
				"\x{2537}",    # t_up    up light, horizontal heavy
				"\x{251D}",    # t_right vertical light, right heavy
				"\x{2525}",    # t_left  vertical light, left heavy
				],
				;
		},
	);

	# Hidden sides take no space and draw nothing: HasBorderStyle gives
	# them a Clay border width of 0, so these glyphs are never painted.
	item Hidden(
		glyphs    => [ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' ],
		locations => [ 0,   0,   0,   0,   0,   0,   0,   0 ],
	);
	item Hkey(
		glyphs    => [ "\x{2594}", "\x{2594}", "\x{2594}", ' ', ' ', "\x{2581}", "\x{2581}", "\x{2581}" ],
		locations => [ 0,          0,          0,          0,   0,   0,          0,          0 ],
	);
	item Inner(
		glyphs    => [ "\x{2597}", "\x{2584}", "\x{2596}", "\x{2590}", "\x{258C}", "\x{259D}", "\x{2580}", "\x{2598}" ],
		locations => [ 1,          1,          1,          1,          1,          1,          1,          1 ],
	);
	item LightShade(
		glyphs    => [ "\x{2591}", "\x{2591}", "\x{2591}", "\x{2591}", "\x{2591}", "\x{2591}", "\x{2591}", "\x{2591}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
	);
	item MediumShade(
		glyphs    => [ "\x{2592}", "\x{2592}", "\x{2592}", "\x{2592}", "\x{2592}", "\x{2592}", "\x{2592}", "\x{2592}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
	);
	item Outer(
		glyphs    => [ "\x{259B}", "\x{2580}", "\x{259C}", "\x{258C}", "\x{2590}", "\x{2599}", "\x{2584}", "\x{259F}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
	);
	item Panel(
		glyphs    => [ "\x{258A}", "\x{2588}", "\x{258E}", "\x{258A}", "\x{258E}", "\x{258A}", "\x{2581}", "\x{258E}" ],
		locations => [ 2,          0,          1,          2,          1,          2,          0,          1 ],
	);
	item Round(
		glyphs    => [ "\x{256D}", "\x{2500}", "\x{256E}", "\x{2502}", "\x{2502}", "\x{2570}", "\x{2500}", "\x{256F}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
		joints    => $solid_joints,
	);

	item Solid(
		glyphs       => [ "\x{250C}", "\x{2500}", "\x{2510}", "\x{2502}", "\x{2502}", "\x{2514}", "\x{2500}", "\x{2518}" ],
		locations    => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
		joints       => $solid_joints,
		mixed_joints => sub {
			Term::Fabulous::Enum::BorderStyle->Heavy, [
				"\x{2542}",    # cross   vertical heavy, horizontal light
				"\x{2530}",    # t_down  down heavy, horizontal light
				"\x{2538}",    # t_up    up heavy, horizontal light
				"\x{2520}",    # t_right vertical heavy, right light
				"\x{2528}",    # t_left  vertical heavy, left light
				],
				Term::Fabulous::Enum::BorderStyle->Double, [
				"\x{256B}",    # cross   vertical double, horizontal single
				"\x{2565}",    # t_down  down double, horizontal single
				"\x{2568}",    # t_up    up double, horizontal single
				"\x{255F}",    # t_right vertical double, right single
				"\x{2562}",    # t_left  vertical double, left single
				],
				;
		}
	);

	item Tall(
		glyphs    => [ "\x{258A}", "\x{2594}", "\x{258E}", "\x{258A}", "\x{258E}", "\x{258A}", "\x{2581}", "\x{258E}" ],
		locations => [ 2,          0,          1,          2,          1,          2,          0,          1 ],
	);
	item Thick(
		glyphs    => [ "\x{2588}", "\x{2580}", "\x{2588}", "\x{2588}", "\x{2588}", "\x{2588}", "\x{2584}", "\x{2588}" ],
		locations => [ 0,          0,          0,          0,          0,          0,          0,          0 ],
	);
	item Vkey(
		glyphs    => [ "\x{258F}", ' ', "\x{2595}", "\x{258F}", "\x{2595}", "\x{258F}", ' ', "\x{2595}" ],
		locations => [ 0,          0,   0,          0,          0,          0,          0,   0 ],
	);
	item Wide(
		glyphs    => [ "\x{2581}", "\x{2581}", "\x{2581}", "\x{258E}", "\x{258A}", "\x{2594}", "\x{2594}", "\x{2594}" ],
		locations => [ 1,          1,          1,          0,          3,          1,          1,          1 ],
	);

	# Renderer-side glyph tables for each border style item above.
	# Sourced from Textualize/textual's `_border.py`:
	#   https://raw.githubusercontent.com/Textualize/textual/refs/heads/main/src/textual/_border.py
	#
	# Textual's BORDER_CHARS / BORDER_LOCATIONS are 3x3 tables:
	#
	#     row 0 (top):     (TL, T,  TR )
	#     row 1 (middle):  (L,  mid, R )
	#     row 2 (bottom):  (BL, B,  BR )
	#
	# The middle-middle cell is always a space pad; we drop it. The remaining
	# 8 cells are flattened in a fixed order and stored as 8-element arrayrefs:
	#
	#     index:  0    1    2    3    4    5    6    7
	#     glyph:  TL   T    TR   L    R    BL   B    BR
	#     source: r0c0 r0c1 r0c2 r1c0 r1c2 r2c0 r2c1 r2c2
	#
	# `glyphs` carries the visible glyph (or a space for invisible / blank styles).
	# 8-element arrayref of glyphs in `[TL, T, TR, L, R, BL, B, BR]` order.
	field $glyphs :param :reader;

	# `locations` carries one of {0,1,2,3} per Textual's location matrix:
	#   0 = widget-side bg   (inner)
	#   1 = parent-side bg   (outer)
	#   2 = reverse(parent_bg, widget_fg)  - Textual's styles[2]
	#   3 = reverse(widget_bg, parent_fg)  - Textual's styles[3]
	# 8-element arrayref of LOCATIONS indices in the same order as `glyphs`.
	field $locations :param :reader;

	# Joint glyph tables for grid-line rendering. Each entry is a
	# 7-element arrayref in fixed order:
	#
	#     index:  0       1       2       3       4       5       6
	#     glyph:  h_line  v_line  cross   t_down  t_up    t_right t_left
	#
	field $joints :param :reader = undef;

	# Mixed-style joint table for grid lines whose horizontal axis
	# style differs from the vertical axis style (or whose perimeter
	# style differs from the meeting interior axis style - same
	# resolution rule).
	#
	#     index:  0      1       2     3        4
	#     glyph:  cross  t_down  t_up  t_right  t_left
	#
	# (h_line / v_line are not in this table - those are
	# axis-uniform and live in `$joints`.)
	#
	# 5-element arrayref `[cross, t_down, t_up, t_right, t_left]` for h_style/v_style intersection.
	field $mixed_joints :param :reader = undef;

	# Helper method to get the subset of styles that support grid joints.
	method get_grid_styles :common () {
		return grep { $_->joints } Term::Fabulous::Enum::BorderStyle->values;
	}

	# `mixed_joints` is a code ref because its tables name items declared
	# later in this enum; it is expanded into this map on first use.
	field $_mixed_joint_by_style_name;

	sub _check_style ( $role, $style ) {
		die "Term::Fabulous::Enum::BorderStyle: the $role style must be a Term::Fabulous::Enum::BorderStyle, got " . ( defined $style ? ( ref $style || "'$style'" ) : 'undef' )
			unless blessed $style && $style->isa('Term::Fabulous::Enum::BorderStyle');
		return;
	}

	# 5-element joint table for grid lines of this (horizontal) style
	# crossing lines of the given vertical style, or undef if there is none.
	method get_mixed_joint ($vertical_style) {
		_check_style( 'vertical', $vertical_style );
		return undef unless defined $mixed_joints;

		$_mixed_joint_by_style_name //= { pairmap { $a->name => $b } $mixed_joints->() };
		return $_mixed_joint_by_style_name->{ $vertical_style->name };
	}

	# Class-method form of get_mixed_joint.
	method get_mixed_joints :common ( $horizontal_style, $vertical_style ) {
		_check_style( 'horizontal', $horizontal_style );
		return $horizontal_style->get_mixed_joint($vertical_style);
	}

	# Styles that draw their joints with the joints of another style (see
	# joints) belong to that style's family for mixed joints.
	state $joint_family = { Round => 'Solid', Dashed => 'Heavy' };

	sub _family_name ($style) {
		return $joint_family->{ $style->name } // $style->name;
	}

	# Which glyph a set of arms needs: [ joints index, mixed index ] for the
	# T shapes and the cross; corners and straight lines are handled apart.
	state $joint_of_arms = {
		'up right down left' => [ 2, 0 ],
		'right down left'    => [ 3, 1 ],
		'up right left'      => [ 4, 2 ],
		'up right down'      => [ 5, 3 ],
		'up down left'       => [ 6, 4 ],
	};
	state $corner_of_arms = { 'right down' => 0, 'down left' => 2, 'up right' => 5, 'up left' => 7 };

	# The glyph where lines of grid styles meet: arms maps up, right, down
	# and left to the style of the line leaving the cell that way, or undef.
	method junction :common (%arms) {
		my @unknown = grep { !/\A(?:up|right|down|left)\z/ } sort keys %arms;
		die "Term::Fabulous::Enum::BorderStyle: junction takes the arms up, right, down and left, got @unknown" if @unknown;
		_check_style( "$_ arm", $arms{$_} ) foreach grep { defined $arms{$_} } sort keys %arms;

		my @directions = grep { defined $arms{$_} && $arms{$_}->joints } qw(up right down left);
		return undef unless @directions;
		my %joining    = map { $_ => $arms{$_} } @directions;    # an arm in a style without joints counts as no line
		my $horizontal = $joining{right} // $joining{left};
		my $vertical   = $joining{down}  // $joining{up};

		my $shape = join ' ', @directions;
		return $horizontal->glyphs->[1] unless defined $vertical;
		return $vertical->glyphs->[3] unless defined $horizontal;
		if ( exists $corner_of_arms->{$shape} ) {
			my $owner = _family_name($horizontal) eq _family_name($vertical) ? $vertical : $horizontal;
			return $owner->glyphs->[ $corner_of_arms->{$shape} ];
		}

		my ( $joint_index, $mixed_index ) = @{ $joint_of_arms->{$shape} };
		return $horizontal->joints->[$joint_index] if _family_name($horizontal) eq _family_name($vertical);
		my $family = Term::Fabulous::Enum::BorderStyle->from_name( _family_name($horizontal) );
		my $mixed  = $family->get_mixed_joint( Term::Fabulous::Enum::BorderStyle->from_name( _family_name($vertical) ) );
		return defined $mixed ? $mixed->[$mixed_index] : $horizontal->joints->[$joint_index];
	}

	method get_top_glyphs () {
		return @{$glyphs}[ 0, 1, 2 ];
	}

	method get_right_glyphs () {
		return @{ $self->glyphs }[4];
	}

	method get_bottom_glyphs () {
		return @{ $self->glyphs }[ 5, 6, 7 ];
	}

	method get_left_glyphs () {
		return @{ $self->glyphs }[3];
	}

	method get_top_locations () {
		return @{$locations}[ 0, 1, 2 ];
	}

	method get_right_locations () {
		return @{$locations}[4];
	}

	method get_bottom_locations () {
		return @{$locations}[ 5, 6, 7 ];
	}

	method get_left_locations () {
		return @{$locations}[3];
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Enum::BorderStyle - The border styles a widget can be drawn with

=head1 SYNOPSIS

	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Widget::Box;

	# A box with a rounded border on all four sides.
	my $box = Term::Fabulous::Widget::Box->new(
		bordered     => 1,
		border_color => [ 180, 200, 220, 255 ],
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
	);

	# A heavier line on top only.
	$box->border_style_top( Term::Fabulous::Enum::BorderStyle->Heavy );

	# Look a style up by its name, for example from a configuration file.
	my $style = Term::Fabulous::Enum::BorderStyle->from_name('Double')
		// die "unknown border style\n";

	# All styles, in the order listed below.
	my @names = map { $_->name } Term::Fabulous::Enum::BorderStyle->values;

=head1 DESCRIPTION

This enumeration holds the 20 border styles Term::Fabulous can draw.
Each style is a single, shared object that you get with a class method
named after the style, for example
C<< Term::Fabulous::Enum::BorderStyle->Round >>. Give it to a widget's
C<border_style> parameter (all four sides) or to one of
C<border_style_top>, C<border_style_right>, C<border_style_bottom> and
C<border_style_left> (one side each); see
L<Term::Fabulous::Role::HasBorderStyle>. A border is only drawn on the
sides where the widget has one (its C<bordered>, or the theme's
C<border.enabled>) and the style is not L</Hidden>; see
L<Term::Fabulous::Manual::Looks/BORDERS>.

In a KDL layout file, a style is named in the C<border> node, for
example C<border style=Round style-top=Heavy> (see
L<Term::Fabulous::Widget::Box/KDL PROPERTIES>).

The styles and their glyphs come from the Python TUI library Textual.
To see all of them, run F<examples/border-showcase.pl> from the
distribution.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/example-border-showcase.svg" alt="Twenty boxes, one in each border style, labeled with the style's name"></p>

=end html

=head1 STYLES

Every style is a class method that returns the style object. Names are
case sensitive.

=head2 Ascii

C<+> corners, C<-> and C<|> lines. Works on every terminal and font.

=head2 Blank

Spaces on the widget's own background: the border takes space but
shows nothing, so the border color has no effect. This is also the
style used for a side that has a positive width but no style.

=head2 Block

A frame of solid block characters drawn half into the parent's
background: lower half blocks on top, full blocks on the sides, upper
half blocks at the bottom.

=head2 DarkShade

Every border cell is a dark shade character (U+2593).

=head2 Dashed

Heavy box-drawing corners with dashed heavy lines.

=head2 Double

Double-line box drawing.

=head2 Heavy

Heavy (bold) box-drawing lines.

=head2 Hidden

The side takes no space and draws nothing, even where the widget has a
border. Use it to switch one side off while the widget's C<bordered>
(or the theme's C<border.enabled>) gives the others; see
L<Term::Fabulous::Role::HasBorderStyle>.

=head2 Hkey

A thin line (upper one eighth block) along the top edge and a thin line
(lower one eighth block) along the bottom edge; the sides are blank.

=head2 Inner

A thin frame of quadrant and half blocks along the inner side of the
border cells; the outer half of the border cells shows the parent's
background.

=head2 LightShade

Every border cell is a light shade character (U+2591).

=head2 MediumShade

Every border cell is a medium shade character (U+2592).

=head2 Outer

A thin frame of quadrant and half blocks along the outer side of the
border cells; the inner half shows the widget's own background.

=head2 Panel

A solid top bar in the border color, with thin bars at the sides and
the bottom; good as a panel with a title row.

=head2 Round

Light box-drawing lines with rounded corners.

=head2 Solid

Light box-drawing lines with square corners.

=head2 Tall

Like L</Panel>, but with a thin top line instead of a solid top bar.

=head2 Thick

Full and half blocks: a thick, solid frame.

=head2 Vkey

Thin vertical bars at the left and right edges; no lines at the top and
bottom.

=head2 Wide

A frame drawn just outside the widget's content: a thin line (lower
one eighth block) along the bottom of the top row, a thin line (upper
one eighth block) along the top of the bottom row, and bars at the
sides. The top and bottom rows show the parent's background.

=head1 METHODS

=head2 values

	my @styles = Term::Fabulous::Enum::BorderStyle->values;

Class method. All styles, in the order of L</STYLES>.

=head2 from_name

	my $style = Term::Fabulous::Enum::BorderStyle->from_name('Round');

Class method. The style with that name, or C<undef> if there is none.
The name is case sensitive: C<'round'> returns C<undef>. KDL layouts use
this lookup for C<border style=Round>.

=head2 from_ordinal

	my $style = Term::Fabulous::Enum::BorderStyle->from_ordinal(0);    # Ascii

Class method. The style at a position of L</values>, counted from 0, or
C<undef> when there is no style at that position.

=head2 name

	say $style->name;    # 'Round'

The name of the style.

=head2 ordinal

	my $position = $style->ordinal;    # 14 for Round

The position of the style in L</values>, counted from 0.

=head2 glyphs

	my ( $top_left, $top, $top_right, $left, $right, $bottom_left, $bottom, $bottom_right ) = @{ $style->glyphs };

An array reference of the eight characters the style draws, in this
order: top-left corner, top edge, top-right corner, left edge, right
edge, bottom-left corner, bottom edge, bottom-right corner.

=head2 locations

	my @codes = @{ $style->locations };

An array reference of eight location codes, one per glyph in the order
of L</glyphs>. The code decides which colors the glyph is drawn in:

=for highlighter language=text

	Code  Foreground                Background
	----  ------------------------  ------------------------------------
	0     border color              the widget's own background
	1     border color              the parent's background
	2     the parent's background   border color (reverse video of 1)
	3     the widget's background   border color (reverse video of 0)

"The parent's background" is the color of the cell just outside the
widget's box on the same side. Codes 2 and 3 use the terminal's reverse
video attribute, which also works when one of the colors is the
terminal default color.

=head2 get_top_glyphs

=for highlighter language=perl

	my ( $left_corner, $edge, $right_corner ) = $style->get_top_glyphs;

The three glyphs of the top side: top-left corner, top edge, top-right
corner.

=head2 get_bottom_glyphs

	my ( $left_corner, $edge, $right_corner ) = $style->get_bottom_glyphs;

The three glyphs of the bottom side: bottom-left corner, bottom edge,
bottom-right corner.

=head2 get_left_glyphs

	my $edge = $style->get_left_glyphs;

The glyph of the left edge.

=head2 get_right_glyphs

	my $edge = $style->get_right_glyphs;

The glyph of the right edge.

=head2 get_top_locations

	my @codes = $style->get_top_locations;

The location codes of L</get_top_glyphs>, in the same order.

=head2 get_bottom_locations

	my @codes = $style->get_bottom_locations;

The location codes of L</get_bottom_glyphs>, in the same order.

=head2 get_left_locations

	my $code = $style->get_left_locations;

The location code of L</get_left_glyphs>.

=head2 get_right_locations

	my $code = $style->get_right_locations;

The location code of L</get_right_glyphs>.

=head1 GRID JOINTS

Some styles also carry the glyphs needed where lines of a grid meet.
L<Term::Fabulous::Widget::Table> draws its grid lines with them (through
L</junction>); the methods are also there for your own widgets.

=head2 joints

	my ( $h_line, $v_line, $cross, $t_down, $t_up, $t_right, $t_left ) = @{ $style->joints };

An array reference of seven glyphs, or C<undef> for styles without
grid joints: horizontal line, vertical line, cross, T pointing down
(a horizontal line with a line going down), T pointing up, T pointing
right and T pointing left. L</Ascii>, L</Dashed>, L</Double>,
L</Heavy>, L</Round> and L</Solid> have joints; L</Dashed> uses the
joints of L</Heavy>, and L</Round> those of L</Solid>.

=head2 junction

	my $glyph = Term::Fabulous::Enum::BorderStyle->junction(
		up    => Term::Fabulous::Enum::BorderStyle->Solid,
		down  => Term::Fabulous::Enum::BorderStyle->Solid,
		right => Term::Fabulous::Enum::BorderStyle->Heavy,
	);    # "\x{251D}", a light vertical line with a heavy line to the right

Class method. The glyph for a cell where lines meet: each of the arms
C<up>, C<right>, C<down> and C<left> names the style of the line that
leaves the cell in that direction (C<undef> or missing: no line). Only
styles with L</joints> take part; an arm in another style counts as no
line. Returns C<undef> when no arm is left.

=over

=item *

One arm, or two opposite arms: the style's own edge glyph (the top
edge for a horizontal line, the left edge for a vertical one), so a
L</Dashed> line stays dashed.

=item *

Two arms at a right angle: a corner glyph from the style's L</glyphs>,
so L</Round> lines get round corners.

=item *

Three arms (a T) or four (a cross): the glyph from L</joints>, or from
L</get_mixed_joint> when the horizontal and the vertical lines belong to
different families (L</Round> counts as L</Solid>, L</Dashed> as
L</Heavy>). Without a mixed table, the horizontal line's joints are
used.

=back

The horizontal style is the one of the C<right> arm, or of the C<left>
arm when there is no right one; the vertical style is the one of the
C<down> arm, or of the C<up> arm. Unknown arm names and arms that are
not style objects die.

=head2 get_grid_styles

	my @styles = Term::Fabulous::Enum::BorderStyle->get_grid_styles;

Class method. The styles that have L</joints>, in the order of
L</values>.

=head2 get_mixed_joint

	my $table = $horizontal_style->get_mixed_joint($vertical_style);
	my ( $cross, $t_down, $t_up, $t_right, $t_left ) = @$table if $table;

The five joint glyphs to use where horizontal lines of this style meet
vertical lines of C<$vertical_style>, as an array reference, or
C<undef> when there is no such table. Tables exist for
L</Double> with L</Solid>, L</Heavy> with L</Solid>, and L</Solid> with
L</Heavy> or L</Double>. Dies if C<$vertical_style> is not a
Term::Fabulous::Enum::BorderStyle object (a style name string is not
enough).

=head2 get_mixed_joints

	my $table = Term::Fabulous::Enum::BorderStyle->get_mixed_joints( $horizontal_style, $vertical_style );

Class method form of L</get_mixed_joint>. Dies if either argument is not
a Term::Fabulous::Enum::BorderStyle object.

=head2 mixed_joints

	my $builder = $style->mixed_joints;    # a code reference, or undef

Internal: a code reference that builds the tables of
L</get_mixed_joint>. Use L</get_mixed_joint> instead.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/BORDERS>, L<Term::Fabulous::Role::HasBorderStyle>,
L<Term::Fabulous::Render::Border>, L<Object::PadX::Enum>,
L<Term::Fabulous::Cookbook::Layout/Use a different border style on each side>.

=cut
