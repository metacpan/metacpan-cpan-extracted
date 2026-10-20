package Term::Fabulous::Widget::Box;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

our $VERSION = '0.05';

class Term::Fabulous::Widget::Box
	:isa(Term::Fabulous::Widget)
	:does(Term::Fabulous::Role::CanParseLayout)
	:strict(params)
{
	use Clay::XS qw(
		Clay_GetElementId CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM
		CLAY_LEFT_TO_RIGHT_WRAP CLAY_BACK_TO_FRONT CLAY_LINE_SIZING_GROW CLAY_LINE_SIZING_FIT
		CLAY_ALIGN_X_LEFT CLAY_ALIGN_X_CENTER CLAY_ALIGN_X_RIGHT CLAY_ALIGN_Y_TOP CLAY_ALIGN_Y_CENTER CLAY_ALIGN_Y_BOTTOM
		CLAY_ATTACH_TO_PARENT CLAY_ATTACH_TO_ROOT CLAY_ATTACH_TO_ELEMENT_WITH_ID
		CLAY_ATTACH_POINT_LEFT_TOP CLAY_ATTACH_POINT_LEFT_CENTER CLAY_ATTACH_POINT_LEFT_BOTTOM
		CLAY_ATTACH_POINT_CENTER_TOP CLAY_ATTACH_POINT_CENTER_CENTER CLAY_ATTACH_POINT_CENTER_BOTTOM
		CLAY_ATTACH_POINT_RIGHT_TOP CLAY_ATTACH_POINT_RIGHT_CENTER CLAY_ATTACH_POINT_RIGHT_BOTTOM
		CLAY_POINTER_CAPTURE_MODE_CAPTURE CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH
		CLAY_CLIP_TO_NONE CLAY_CLIP_TO_ATTACHED_PARENT
		CLAY__SIZING_TYPE_FIXED
	);
	use List::Util qw(max sum0);
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Check qw(border_style describe integer non_negative_integer one_of sizing);

	my %DIRECTION_BY_NAME = (
		top_to_bottom      => CLAY_TOP_TO_BOTTOM,
		ttb                => CLAY_TOP_TO_BOTTOM,
		down               => CLAY_TOP_TO_BOTTOM,
		left_to_right      => CLAY_LEFT_TO_RIGHT,
		ltr                => CLAY_LEFT_TO_RIGHT,
		right              => CLAY_LEFT_TO_RIGHT,
		wrap               => CLAY_LEFT_TO_RIGHT_WRAP,
		ltr_wrap           => CLAY_LEFT_TO_RIGHT_WRAP,
		left_to_right_wrap => CLAY_LEFT_TO_RIGHT_WRAP,
		stack              => CLAY_BACK_TO_FRONT,
		back_to_front      => CLAY_BACK_TO_FRONT,
		btf                => CLAY_BACK_TO_FRONT,
	);

	my %LINE_SIZING_BY_NAME = ( grow => CLAY_LINE_SIZING_GROW, fit => CLAY_LINE_SIZING_FIT );

	my %ALIGN_X_BY_NAME = ( left => CLAY_ALIGN_X_LEFT, center => CLAY_ALIGN_X_CENTER, right  => CLAY_ALIGN_X_RIGHT );
	my %ALIGN_Y_BY_NAME = ( top  => CLAY_ALIGN_Y_TOP,  center => CLAY_ALIGN_Y_CENTER, bottom => CLAY_ALIGN_Y_BOTTOM );

	my %ATTACH_TO_BY_NAME = (
		parent  => CLAY_ATTACH_TO_PARENT,
		root    => CLAY_ATTACH_TO_ROOT,
		element => CLAY_ATTACH_TO_ELEMENT_WITH_ID,
	);

	my %ATTACH_POINT_BY_NAME = (
		left_top      => CLAY_ATTACH_POINT_LEFT_TOP,
		left_center   => CLAY_ATTACH_POINT_LEFT_CENTER,
		left_bottom   => CLAY_ATTACH_POINT_LEFT_BOTTOM,
		center_top    => CLAY_ATTACH_POINT_CENTER_TOP,
		center_center => CLAY_ATTACH_POINT_CENTER_CENTER,
		center_bottom => CLAY_ATTACH_POINT_CENTER_BOTTOM,
		right_top     => CLAY_ATTACH_POINT_RIGHT_TOP,
		right_center  => CLAY_ATTACH_POINT_RIGHT_CENTER,
		right_bottom  => CLAY_ATTACH_POINT_RIGHT_BOTTOM,
	);

	my %POINTER_CAPTURE_BY_NAME = ( capture => CLAY_POINTER_CAPTURE_MODE_CAPTURE, passthrough     => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH );
	my %CLIP_TO_BY_NAME         = ( none    => CLAY_CLIP_TO_NONE,                 attached_parent => CLAY_CLIP_TO_ATTACHED_PARENT );

	# Each key of a floating node: where its value goes in the
	# Clay_FloatingElementConfig hash (a key, or a key and a subkey), and
	# how the KDL value is parsed.
	my %FLOATING_KEY = (
		attach_to       => [ ['attach_to'],                  sub ( $box, $value ) { _named( 'floating attach_to', \%ATTACH_TO_BY_NAME, $value ) } ],
		parent_id       => [ ['parent_id'],                  sub ( $box, $value ) { _element_id( 'floating parent_id', $value ) } ],
		element         => [ [ attach_points => 'element' ], sub ( $box, $value ) { _named( 'floating element', \%ATTACH_POINT_BY_NAME, $value ) } ],
		parent          => [ [ attach_points => 'parent' ],  sub ( $box, $value ) { _named( 'floating parent', \%ATTACH_POINT_BY_NAME, $value ) } ],
		offset_x        => [ [ offset => 'x' ],              sub ( $box, $value ) { integer( $box, 'floating offset_x', $value ) } ],
		offset_y        => [ [ offset => 'y' ],              sub ( $box, $value ) { integer( $box, 'floating offset_y', $value ) } ],
		z_index         => [ ['z_index'],                    sub ( $box, $value ) { integer( $box, 'floating z_index', $value ) } ],
		pointer_capture => [ ['pointer_capture_mode'],       sub ( $box, $value ) { _named( 'floating pointer_capture', \%POINTER_CAPTURE_BY_NAME, $value ) } ],
		clip_to         => [ ['clip_to'],                    sub ( $box, $value ) { _named( 'floating clip_to', \%CLIP_TO_BY_NAME, $value ) } ],
	);

	# The value a name stands for in %$value_by_name; an unknown name dies
	# with the known ones.
	sub _named ( $what, $value_by_name, $name ) {
		return $value_by_name->{ one_of( 'Term::Fabulous::Widget::Box', $what, $name, keys %$value_by_name ) };
	}

	# The Clay element id number of the widget with the id $id, hashed the
	# way Clay::UI hashes widget ids.
	sub _element_id ( $what, $id ) {
		die "Term::Fabulous::Widget::Box: $what must be a widget id, got " . describe($id) unless defined $id && length $id;
		return Clay_GetElementId($id)->{id};
	}

	sub _sizing ( $axis, $spec ) {
		return sizing( 'Term::Fabulous::Widget::Box', "sizing $axis", $spec // '' );
	}

	# ---------------------------------------------------------------------
	# Height before layout
	# ---------------------------------------------------------------------

	# The rows the children take: one under the other, their rows and the
	# gaps between them add up; side by side, each child gets its fixed
	# width or an equal share of the rest, and the tallest decides. Other
	# directions take the tallest child too. A child without an estimate
	# counts one row.
	method estimated_content_rows :override ($columns) {
		my @children = @{ $self->layout_children };
		return 0 unless @children;
		my $layout    = $self->layout;
		my $direction = $layout->{layout_direction} // CLAY_LEFT_TO_RIGHT;
		my $gap       = $layout->{child_gap}        // 0;
		return sum0( map { _estimated_rows_of( $_, $columns ) } @children ) + $gap * ( @children - 1 ) if $direction == CLAY_TOP_TO_BOTTOM;
		return max( map { _estimated_rows_of( $_, $columns ) } @children ) unless $direction == CLAY_LEFT_TO_RIGHT;

		my %fixed     = map  { refaddr($_) => _fixed_columns_of($_) } @children;
		my @flexible  = grep { !defined $fixed{ refaddr $_ } } @children;
		my $remaining = max( 1, $columns - sum0( grep { defined } values %fixed ) - $gap * ( @children - 1 ) );
		my $share     = max( 1, int( $remaining / max( 1, scalar @flexible ) ) );
		return max( map { _estimated_rows_of( $_, $fixed{ refaddr $_ } // $share ) } @children );
	}

	sub _estimated_rows_of ( $child, $columns ) {
		return $child->can('estimated_rows') ? $child->estimated_rows($columns) : 1;
	}

	# The width a child was given as a fixed sizing, or undef.
	sub _fixed_columns_of ($child) {
		return undef unless $child->can('layout');
		my $width = $child->layout->{sizing}{width};
		return defined $width && $width->{type} == CLAY__SIZING_TYPE_FIXED ? $width->{min} : undef;
	}

	method layout_properties :common () {
		return (
			background_color    => 'color',
			classes             => \&_parse_classes,
			glyphs_show_through => 'boolean',
			border_color        => 'color',
			width_group         => 'scalar',
			height_group        => 'scalar',
			layout              => \&_parse_layout,
			border              => \&_parse_border,
			sizing              => \&_parse_sizing,
			padding             => \&_parse_padding,
			child_alignment     => \&_parse_child_alignment,
			floating            => \&_parse_floating,
		);
	}

	method _parse_classes ($kid) {
		$self->classes( $self->kdl_strings($kid) );
		return;
	}

	method _parse_layout ($kid) {
		my $props = $self->kdl_properties( $kid, qw(direction child_gap gap line_gap line_sizing) );
		die "Term::Fabulous::Widget::Box: layout accepts 'child_gap' or its alias 'gap', not both"
			if exists $props->{child_gap} && exists $props->{gap};

		my %layout = %{ $self->layout };
		if ( exists $props->{direction} ) {
			$layout{layout_direction} = _named( 'layout direction', \%DIRECTION_BY_NAME, $props->{direction} );
		}
		foreach my $gap_name ( grep { exists $props->{$_} } qw(child_gap gap) ) {
			$layout{child_gap} = non_negative_integer( $self, "layout $gap_name", $props->{$gap_name} );
		}
		$layout{line_gap}    = non_negative_integer( $self, 'layout line_gap', $props->{line_gap} ) if exists $props->{line_gap};
		$layout{line_sizing} = _named( 'layout line_sizing', \%LINE_SIZING_BY_NAME, $props->{line_sizing} ) if exists $props->{line_sizing};
		$self->layout( \%layout );
		return;
	}

	method _parse_border ($kid) {
		my @sides = qw(top right bottom left);
		my $props = $self->kdl_properties( $kid, 'style', ( map { "style-$_" } @sides ), 'color' );

		foreach my $side (@sides) {
			my ($style_key) = grep { exists $props->{$_} } ( "style-$side", 'style' );    # the side key wins
			next unless defined $style_key;
			my $accessor = "border_style_$side";
			$self->$accessor( border_style( $self, "border $style_key", $props->{$style_key} ) );
		}
		$self->border_color( $props->{color} ) if exists $props->{color};
		return;
	}

	method _parse_sizing ($kid) {
		my $props  = $self->kdl_properties( $kid, qw(width height) );
		my %layout = %{ $self->layout };
		$layout{sizing} = { %{ $layout{sizing} // {} }, map { $_ => _sizing( $_, $props->{$_} ) } keys %$props };
		$self->layout( \%layout );
		return;
	}

	method _parse_padding ($kid) {
		my $props  = $self->kdl_properties( $kid, qw(left right top bottom) );
		my %layout = %{ $self->layout };
		$layout{padding} = { %{ $layout{padding} // {} }, map { $_ => non_negative_integer( $self, "padding $_", $props->{$_} ) } keys %$props };
		$self->layout( \%layout );
		return;
	}

	method _parse_child_alignment ($kid) {
		my $props            = $self->kdl_properties( $kid, qw(x y) );
		my %alignment_by_key = ( x => \%ALIGN_X_BY_NAME, y => \%ALIGN_Y_BY_NAME );
		my %layout           = %{ $self->layout };
		$layout{child_alignment} = { %{ $layout{child_alignment} // {} }, map { $_ => _named( "child_alignment $_", $alignment_by_key{$_}, $props->{$_} ) } keys %$props };
		$self->layout( \%layout );
		return;
	}

	method _parse_floating ($kid) {
		my $props    = $self->kdl_properties( $kid, qw(attach_to parent_id element parent offset_x offset_y z_index pointer_capture clip_to) );
		my %floating = %{ $self->floating // {} };
		foreach my $key ( sort keys %$props ) {
			my ( $slot,  $parse )    = $FLOATING_KEY{$key}->@*;
			my ( $field, $subfield ) = @$slot;
			my $value = $parse->( $self, $props->{$key} );
			$floating{$field} = defined $subfield ? { %{ $floating{$field} // {} }, $subfield => $value } : $value;
		}
		$floating{attach_to} //= CLAY_ATTACH_TO_PARENT;    # a floating node means "float"
		die "Term::Fabulous::Widget::Box: floating attach_to=element needs parent_id"
			if ( $floating{attach_to} // -1 ) == CLAY_ATTACH_TO_ELEMENT_WITH_ID && !defined $floating{parent_id};
		$self->floating( \%floating );
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Box - The general-purpose container widget

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Enum::BorderStyle;
	use Clay::XS qw(sizing_grow sizing_fit CLAY_TOP_TO_BOTTOM);

	my $card = Term::Fabulous::Widget::Box->new(
		id               => 'card',
		layout           => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_fit() },
			padding          => { left => 1, right => 1 },
			child_gap        => 1,
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 97, 175, 239, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);
	$card->add_child(
		Term::Fabulous::Widget::Text->new( text => 'Title',     text_color => [ 255, 255, 255, 255 ] ),
		Term::Fabulous::Widget::Text->new( text => 'Body text', text_color => [ 200, 205, 215, 255 ] ),
	);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-box.svg" alt="A card with a title and body text, and three boxes labeled fit, grow and fixed(14)"></p>

=end html

=head1 DESCRIPTION

A Box is a rectangle that holds other widgets and arranges them in a
row or a column. It can have a background color and a border, and it
can receive events. Boxes are the building blocks of every screen:
nest them to divide the terminal into areas, then put
L<Term::Fabulous::Widget::Text> and the other widgets inside.

Box is the concrete form of L<Term::Fabulous::Widget>; most other
widgets (L<Term::Fabulous::Widget::Button>,
L<Term::Fabulous::Widget::ScrollBox>, L<Term::Fabulous::Widget::Canvas>,
the input widgets) are Boxes with extra behavior. A Box can also be
built from a KDL layout file (see L</KDL PROPERTIES>).

The SYNOPSIS above draws this (colors left out):

=for highlighter language=text

	+----------------------------+
	| Title                      |
	|                            |
	| Body text                  |
	+----------------------------+

with rounded corners. The border takes one cell on every side and the
padding one more cell left and right; see
L<Term::Fabulous::Role::HasBorderStyle/Border space>.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $box = Term::Fabulous::Widget::Box->new(%parameters);

All parameters are optional; unknown parameters die. A Box accepts the
parameters common to all container widgets. Each is listed here with
its meaning in one sentence;
L<the constructor of Term::Fabulous::Widget|Term::Fabulous::Widget/new>
describes the accepted values in full.

=over

=item C<id>

A string that names the widget and must be unique in the widget tree.
Default: C<undef> (no id).

=item C<layout>

A hash reference with the keys C<sizing>, C<padding>, C<child_gap>,
C<layout_direction>, C<child_alignment>, C<line_gap> and
C<line_sizing> that decides the size of
the box and how its children are arranged. Default: C<{}>, which fits
the box to its content and places the children from left to right.

=item C<floating>

A hash reference that takes the box out of its parent's layout and
draws it on top of other widgets, attached to its parent, the root or
another widget. Default: C<undef> (the box is laid out normally).

=item C<background_color>

The color of the box's area, in any format L<Term::Fabulous::Color>
accepts (C<[r, g, b, a]>, C<{ r, g, b, a }>, a string such as
C<'#14192b'>, a Color object). Default: C<undef>, so the box is
transparent.

=item C<glyphs_show_through>

A boolean. Default: false. With a translucent C<background_color>,
whether text and borders below the box stay visible through it.

=item C<bordered>

Which sides have a border: a true value for all four sides, or a hash
reference with any of C<left>, C<right>, C<top> and C<bottom> and true
or false values. Default: no border; the theme has no
C<border.enabled> for a Box (see L<Term::Fabulous::Widget/bordered>).

=item C<border_color>

The color of the border glyphs, in the same formats as
C<background_color>. Default: the theme's C<box.border.color>, the
C<border> token in the built-in themes (see
L<Term::Fabulous::Manual::Looks/THEMES>).

=item C<border_style>

A L<Term::Fabulous::Enum::BorderStyle> item or its name (C<'Round'>)
that sets the style of every side that has no side parameter of its
own. Default: the theme's C<box.border.style>, C<Round> in the
built-in themes (see L<Term::Fabulous::Manual::Looks/THEMES>).

=item C<border_style_top>

=item C<border_style_right>

=item C<border_style_bottom>

=item C<border_style_left>

A L<Term::Fabulous::Enum::BorderStyle> item or its name that sets the
style of one side. Default: C<undef>. It wins over C<border_style> for
that side.

=item C<border_corners>

A hash reference of glyphs drawn at the corners instead of the style's
corner glyphs. Default: C<undef>.

=item C<outer_border_sides>

An array reference of sides whose border glyphs are drawn on the
background outside the box. Default: C<[]>.

=item C<width_group>

=item C<height_group>

A sizing group number that gives the box the same width (or height) as
the other widgets with that number. Default: 0, which means no group.

=item C<classes>

An array reference of free-form names, returned by
L<Term::Fabulous::Widget/get_classes>. Default: C<[]>.

=back

=head1 METHODS

A Box has all methods of L<Term::Fabulous::Widget>: children
(C<add_child>, C<remove_child>, C<children>, ...), events (C<on>,
C<fire_event>), the search L<Term::Fabulous::Widget/find_by_id>, the
accessors C<layout>, C<floating>, C<background_color>,
C<glyphs_show_through>, C<border_color>, C<bordered>,
C<border_style_top>, C<border_style_right>, C<border_style_bottom>,
C<border_style_left>, C<width_group> and C<height_group>, and the state
methods. It adds nothing of its own except how it estimates its rows
(L</estimated_rows>), which matters to widget authors, as do the methods
in L</SUBCLASS INTERFACE>.

=head2 estimated_rows

	my $rows = $box->estimated_rows($columns);

The rows the box will take in that many columns, before Clay has laid
it out (see L<Term::Fabulous::Widget/estimated_rows>). A fixed height
in the layout is the answer; otherwise it is its padding and border
around its children's estimates. Children one under the other add up,
with the child gap between them; side by side, a child with a fixed
width gets that width, the others share the rest, and the tallest
decides. In any other direction (stacked, wrapping) the tallest child
decides; a box without children counts only its padding and border. A
child without an estimate counts one row. Box does this in
C<estimated_content_rows> (see
L<Term::Fabulous::Widget/estimated_content_rows>).

=head1 EVENTS

A Box fires no events of its own. Events fired on its children bubble
up to it (see L<Term::Fabulous::Manual::Events/EVENTS>), and
L<Term::Fabulous> fires C<KeyPress> on it when it is the root and
nothing has the focus, and C<Mouse> when it is the topmost widget
painted under the pointer. A Box receives C<Mouse> events only on the
cells it paints: its whole area when it has a background color, and
only its border cells when it has a border but no background. A Box
with neither is transparent to the mouse.

=head1 KDL PROPERTIES

A Box built by L<Term::Fabulous::Layout> reads these property nodes
from its block. Child nodes whose names start with an uppercase letter
are child widgets; everything else is a property. Unknown properties,
unknown keys and invalid values die, naming the property.

=for highlighter language=kdl

	use Term::Fabulous::Widget::Box as Box
	use Term::Fabulous::Widget::Text as Text

	Box "card" {
		layout direction=down gap=1
		sizing width="fixed(30)" height="fit(3, 10)"
		padding left=1 right=1
		child_alignment x=center
		border style=Round color="#61afef"
		bordered #true
		background_color "rgb(30, 35, 50)"

		Text { text "Title"; text_color "#ffffff"; }
		Text { text "Body text"; text_color "hsl(220, 15%, 80%)"; }
	}

=over

=item C<layout direction=... gap=N line_gap=N line_sizing=...>

C<direction> is C<down> (aliases C<ttb>, C<top_to_bottom>), C<right>
(aliases C<ltr>, C<left_to_right>), C<wrap> (aliases C<ltr_wrap>,
C<left_to_right_wrap>; see L<Term::Fabulous::Manual::Layout/Flow layout>) or
C<stack> (aliases C<back_to_front>, C<btf>; see
L<Term::Fabulous::Manual::Layout/Stack layout>).
C<gap> (alias C<child_gap>; giving both dies) is the number of cells
between children, a non-negative integer. C<line_gap> is the number of
rows between the lines of a C<wrap> box, a non-negative integer.
C<line_sizing> is C<grow> (the default) or C<fit> and decides what a
C<wrap> box taller than its lines does with the leftover rows. Each key
is optional, but at least one must be given: a bare C<layout> node
dies.

=item C<sizing width=... height=...>

Each value is C<grow>, C<fit>, C<"grow(MIN)">, C<"grow(MIN, MAX)">,
C<"fit(MIN)">, C<"fit(MIN, MAX)">, C<"fixed(N)"> with N a non-negative
integer number of cells, or C<"percent(N)"> with N a number from 0 to
100 (C<"percent(50)"> is half of the parent; note that Perl code uses a
fraction instead: C<sizing_percent(0.5)>). MIN and MAX are
non-negative integer numbers of cells, the limits of
C<sizing_grow($min, $max)> and C<sizing_fit($min, $max)>; without MAX
there is no maximum, and a MIN greater than MAX dies. Values with
parentheses must be quoted. Either key may be left out. A second
C<sizing> node changes only the axes it names.

=item C<child_alignment x=... y=...>

Where the children are placed when they do not fill the box: C<x> is
C<left> (the default), C<center> or C<right>, C<y> is C<top> (the
default), C<center> or C<bottom>. Either key may be left out, but at
least one must be given. A second C<child_alignment> node changes only
the key it names. An unknown name dies with the known ones.

=item C<floating attach_to=... parent_id=... element=... parent=... offset_x=N offset_y=N z_index=N pointer_capture=... clip_to=...>

Sets the C<floating> hash (see L<Term::Fabulous::Widget/floating>).
Each key is optional, but at least one must be given:

=over

=item C<attach_to>

C<parent> (the default), C<root> or C<element>. C<element> requires
C<parent_id>.

=item C<parent_id>

The id of the widget to attach to with C<attach_to=element>, a string.

=item C<element>

=item C<parent>

The point of this box (C<element>) that is placed on the point of the
widget it is attached to (C<parent>): C<left_top> (the default),
C<left_center>, C<left_bottom>, C<center_top>, C<center_center>,
C<center_bottom>, C<right_top>, C<right_center> or C<right_bottom>.

=item C<offset_x>

=item C<offset_y>

Integers added to the position, in cells; negative values move left
and up.

=item C<z_index>

An integer from -32768 to 32767; floating widgets with a higher value
are drawn on top.

=item C<pointer_capture>

C<capture> (the default) or C<passthrough>.

=item C<clip_to>

C<none> (the default) or C<attached_parent>.

=back

A second C<floating> node changes only the keys it names. An unknown
name dies with the known ones.

	Box "menu" {
		floating attach_to=element parent_id="menu-button" element=left_top parent=left_bottom
		floating z_index=10
		border style=Round
		bordered #true
	}

=item C<padding left=N right=N top=N bottom=N>

Any subset of the four sides; non-negative integers. A second
C<padding> node changes only the sides it names, like C<sizing>.

=item C<border style=... style-top=... style-right=... style-bottom=... style-left=... color=...>

C<style> sets all four sides, C<style-top> and the other side keys
override it for one side. Values are the names of
L<Term::Fabulous::Enum::BorderStyle> items (C<Round>, C<Solid>,
C<Double>, ...). C<color> takes any color string that
L<Term::Fabulous::Color> understands (C<"#61afef">,
C<"rgb(97, 175, 239)">, C<"hsl(207, 82%, 66%)">, ...). This property
does not make a border appear: also give C<bordered>.

=item C<bordered #true> or C<bordered top=#true right=#true bottom=#true left=#true>

A border on all four sides, or on the sides named C<#true>; the sides
left out have none. C<#false> (or C<0>) gives no border. Any other
value dies, a quoted C<"true"> included.

=item C<background_color "...">

=item C<border_color "...">

Any L<Term::Fabulous::Color> string.

=item C<glyphs_show_through #true>

C<#true> or C<#false> (the default), see
L<Term::Fabulous::Widget/glyphs_show_through>.

=item C<width_group N>

=item C<height_group N>

Sizing group numbers, see L<Term::Fabulous::Widget/width_group>.

=back

C<border_corners>, C<outer_border_sides> and C<classes> cannot be set
from KDL; set them in Perl after the build (see
L<Term::Fabulous::Layout/LIMITATIONS>).

=head1 SUBCLASS INTERFACE

This method is for authors of widget classes that should be buildable
from KDL layouts. See L<Term::Fabulous::Role::CanParseLayout>, which
also provides C<apply_layout_node> and C<apply_layout_settings>.

=head2 layout_properties

=for highlighter language=perl

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, title => 'scalar', collapsed => 'boolean', shortcut => \&_parse_shortcut );
	}

The table of the properties a layout may set and how each is read (see
L<Term::Fabulous::Role::CanParseLayout/layout_properties>). For a Box:
C<background_color> and C<border_color> are colors,
C<glyphs_show_through> is a boolean, C<width_group> and
C<height_group> are scalars, and C<layout>, C<border>, C<sizing>,
C<padding>, C<child_alignment> and C<floating> are structured
properties the Box parses itself (see L</KDL PROPERTIES>). C<bordered>
is a layout property by itself, as a themed parameter (see
L<Term::Fabulous::Role::CanParseLayout/layout_properties>). Subclasses
extend the table as shown.

=head1 SEE ALSO

L<Term::Fabulous::Widget> for the common parameters and methods,
L<Term::Fabulous::Manual::Layout/LAYOUT> (every layout option with a
picture), the example program F<examples/widgets/box.pl>, L<Term::Fabulous::Layout>,
L<Term::Fabulous::Role::HasBorderStyle>,
L<Term::Fabulous::Cookbook::Layout/Line up labels with equal widths (width_group)>,
L<Term::Fabulous::Cookbook::Layout/Use a different border style on each side>.

=cut
