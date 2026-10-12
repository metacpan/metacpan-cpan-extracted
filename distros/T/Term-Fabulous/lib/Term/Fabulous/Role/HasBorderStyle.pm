package Term::Fabulous::Role::HasBorderStyle;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

role Term::Fabulous::Role::HasBorderStyle {
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Check qw(border_style describe glyph optional);
	use Term::Fabulous::Enum::BorderStyle;

	# The theme's value of a slot of the widget's family
	# (Term::Fabulous::Role::Themed): the border.style a side falls back to.
	method look;

	my @SIDES = qw(left right top bottom);

	# The style the program gave each side, or none.
	field %_style_of_side;
	field $border_corners     :param = undef;
	field $outer_border_sides :param = [];

	my @CORNERS = qw(top_left top_right bottom_left bottom_right);

	ADJUST {
		$border_corners     = _corner_glyphs( $self, $border_corners );
		$outer_border_sides = _side_names( $self, $outer_border_sides );
	}

	# A side parameter wins over border_style, which fills the others.
	ADJUST :params ( :$border_style = undef, :$border_style_top = undef, :$border_style_right = undef, :$border_style_bottom = undef, :$border_style_left = undef ) {
		my %given = ( top => $border_style_top, right => $border_style_right, bottom => $border_style_bottom, left => $border_style_left );
		my $all   = optional( \&border_style, $self, border_style => $border_style );
		foreach my $side (@SIDES) {
			my $style = optional( \&border_style, $self, "border_style_$side" => $given{$side} );
			$_style_of_side{$side} = $style // $all;
		}
	}

	# A copy of a list of side names, each at most once, in @SIDES order.
	sub _side_names ( $owner, $sides ) {
		die ref($owner) . ": outer_border_sides must be an array reference of side names, got " . describe($sides)
			unless ref $sides eq 'ARRAY';
		my %is_side = map  { $_ => 1 } @SIDES;
		my @unknown = grep { !defined || ref || !$is_side{$_} } @$sides;
		die ref($owner) . ": outer_border_sides knows only the sides @SIDES, got " . join( ', ', map { defined $_ ? "'$_'" : 'undef' } @unknown ) if @unknown;
		my %wanted = map { $_ => 1 } @$sides;
		return [ grep { $wanted{$_} } @SIDES ];
	}

	method outer_border_sides (@new) {
		return [@$outer_border_sides] unless @new;
		$outer_border_sides = _side_names( $self, $new[0] );
		$self->mark_changed;
		return [@$outer_border_sides];
	}

	# Whether a side is drawn on the background outside the widget. Read by
	# Term::Fabulous::Render::Border.
	method is_outer_border_side ($side) {
		return ( grep { $_ eq $side } @$outer_border_sides ) ? 1 : 0;
	}

	# Hand-written accessors, so that writing a style marks the widget
	# changed and reading one answers the style the side is drawn in.
	method border_style_top    (@new) { return $self->_border_style( top    => @new ) }
	method border_style_right  (@new) { return $self->_border_style( right  => @new ) }
	method border_style_bottom (@new) { return $self->_border_style( bottom => @new ) }
	method border_style_left   (@new) { return $self->_border_style( left   => @new ) }

	method _border_style ( $side, @new ) {
		return $self->border_style_of($side) unless @new;
		$_style_of_side{$side} = optional( \&border_style, $self, "border_style_$side" => $new[0] );
		$self->mark_changed;
		return $_style_of_side{$side};
	}

	# The style a side is drawn in: the program's, else the one the widget
	# derives (derived_border_style), else the theme's border.style for the
	# widget, else Blank. Term::Fabulous::Render::Border draws with it.
	method border_style_of ($side) {
		die ref($self) . ": border_style_of takes a side (@SIDES), got " . describe($side) unless defined $side && !ref $side && exists $_style_of_side{$side};
		return $_style_of_side{$side} // $self->_derived_border_style($side) // $self->look('border.style') // Term::Fabulous::Enum::BorderStyle->Blank;
	}

	method _derived_border_style ($side) {
		return $self->can('derived_border_style') ? $self->derived_border_style($side) : undef;
	}

	# A copy of a corner glyph hash: undef, or a hash of single glyphs one
	# column wide under the names in @CORNERS.
	sub _corner_glyphs ( $owner, $corners ) {
		return undef unless defined $corners;
		die ref($owner) . ": border_corners must be undef or a hash reference of corner glyphs, got " . describe($corners)
			unless ref $corners eq 'HASH';
		my %is_corner = map  { $_ => 1 } @CORNERS;
		my @unknown   = grep { !$is_corner{$_} } sort keys %$corners;
		die ref($owner) . ": border_corners does not know @unknown (known: @CORNERS)" if @unknown;
		return { map { $_ => glyph( $owner, "border_corners $_", $corners->{$_} ) } grep { defined $corners->{$_} } sort keys %$corners };
	}

	method border_corners (@new) {
		return defined $border_corners ? {%$border_corners} : undef unless @new;
		$border_corners = _corner_glyphs( $self, $new[0] );
		$self->mark_changed;
		return defined $border_corners ? {%$border_corners} : undef;
	}

	# The glyph drawn at a corner instead of the style's corner glyph, or
	# undef. Read by Term::Fabulous::Render::Border.
	method border_corner_glyph ($corner) {
		return defined $border_corners ? $border_corners->{$corner} : undef;
	}

	# The sides the widget has a border on (Term::Fabulous::Widget/bordered),
	# as a shared hash of all four sides that must not be changed.
	method _bordered_sides;

	# The sides a border is drawn on and takes room on: the bordered sides
	# whose style is not Hidden. A new hash of all four sides, 1 or 0.
	method drawn_border_sides () {
		return $self->_drawn_sides // { map { $_ => 0 } @SIDES };
	}

	# The same, or undef when no side is drawn: the contributors run for
	# every widget in every frame, and most widgets have no border.
	method _drawn_sides () {
		my $bordered = $self->_bordered_sides;
		return undef unless grep { $bordered->{$_} } @SIDES;
		my $hidden = Term::Fabulous::Enum::BorderStyle->Hidden;
		my %drawn  = map { $_ => $bordered->{$_} && refaddr( $self->border_style_of($_) ) != refaddr($hidden) ? 1 : 0 } @SIDES;
		return ( grep { $drawn{$_} } @SIDES ) ? \%drawn : undef;
	}

	# The width of every side for Clay: 1 where a border is drawn, else 0.
	# Clay::UI runs the contribute_* methods in alphabetical order, so this
	# runs after contribute_border, which wrote the color the program gave,
	# and before contribute_look_theme, which colors the border from the
	# theme. Writes a fresh hash, so the border slice is never modified.
	method contribute_border_sides ($config) {
		my $drawn = $self->_drawn_sides // return;

		$config->{border} = { %{ $config->{border} // {} }, width => { %$drawn, between_children => 0 } };
		return;
	}

	# Clay draws borders over the content box, so every drawn side adds a
	# cell to the padding: borders occupy cells inside the widget and the
	# user's padding starts after them. Clay::UI runs contribute_* methods
	# in alphabetical order, so the name sorts after contribute_layout;
	# that way the inset is applied to the final layout slice. Writes fresh
	# hashes, so the widget's own layout is never modified.
	method contribute_layout_inset ($config) {
		my $drawn = $self->_drawn_sides // return;

		my $layout  = $config->{layout}  // {};
		my $padding = $layout->{padding} // {};
		die "Term::Fabulous::Role::HasBorderStyle: layout padding must be a hash reference"
			unless ref $padding eq 'HASH';

		$config->{layout} = {
			%$layout,
			padding => { %$padding, map { $_ => ( $padding->{$_} // 0 ) + $drawn->{$_} } @SIDES },
		};
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::HasBorderStyle - Border glyphs per side, and
borders that take space

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Enum::BorderStyle;

	my $box = Term::Fabulous::Widget::Box->new(
		bordered     => 1,
		border_color => [ 180, 200, 220, 255 ],
		border_style => Term::Fabulous::Enum::BorderStyle->Round,    # all four sides
		layout       => { padding => { left => 1, right => 1 } },    # inside the border
	);

	# Change one side later:
	$box->border_style_top( Term::Fabulous::Enum::BorderStyle->Double );

=head1 DESCRIPTION

This role is part of every L<Term::Fabulous::Widget> (and therefore of
every Box, Button, ScrollBox, Canvas and input widget). It does two
things:

=over

=item 1.

It adds the border style parameters and accessors, which choose the
characters a border is drawn with (Clay itself only knows where a
border is and its color).

=item 2.

It makes borders take space in the layout, so that the content never
overlaps them.

=back

You do not compose this role yourself; it is already part of the
widget classes. A widget has a border on the sides
L<Term::Fabulous::Widget/bordered> names, given by the program or by
the theme's C<border.enabled>, drawn in a border style and a
C<border_color> that the program or the theme gives:

	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 180, 200, 220, 255 ],

L<The borders section of the looks guide|Term::Fabulous::Manual::Looks/BORDERS>
explains borders with examples. F<examples/border-options.pl> shows a
border on some sides, per-side styles, padding inside a border, a
C<Hidden> side, C<border_corners> and C<outer_border_sides>:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/example-border-options.svg" alt="Six bordered panels: a border on the left and top only; a solid border with a double top and a thick left side; a round border with a cell of padding inside; a round border with a hidden bottom side; a title box and a body box sharing one line; a round border drawn on the parent's background"></p>

=end html

=head2 How a border is drawn

=over

=item * A side is drawn when the widget has a border on it (see
L<Term::Fabulous::Widget/bordered>) and its style is not C<Hidden>. It
is one cell thick. L</drawn_border_sides> answers which sides are
drawn.

=item * A side with the C<Hidden> style is switched off: it draws
nothing and takes no space, even where the widget has a border. Use it
to turn one side of a border off while the rest comes from the theme's
C<border.enabled>, which switches all four sides.

=item * The top and bottom sides are drawn over the whole width of the
widget and own the corners: a corner glyph appears where the top or
bottom row meets a drawn left or right side, taken from the style of
the top or bottom side. The left and right sides fill the rows between.

=item * A side is drawn in the style L</border_style_of> answers: its
own style, else the style the widget derives for it (see
L</derived_border_style>), else the style the theme gives the
widget's family (C<border.style>), else the C<Blank> style, that is
with spaces. A C<Hidden> style from any of these switches the side
off.

=item * C<border_corners> replaces the glyph of any corner, for example
to join the box to lines around it (C<\x{251C}> instead of
C<\x{250C}> where a line comes in from above). The corner keeps the
colors its style gives it.

=item * C<outer_border_sides> draws some sides on the background
outside the widget instead of its own (see below).

=item * The glyphs have the C<border_color> (the terminal's default
foreground color when none is set). Their background is usually the
widget's background; some styles, such as C<Block>, C<Inner>, C<Panel>
or C<Wide>, use the background outside the widget or reverse video for
some glyphs so that they blend with the surroundings. See
L<Term::Fabulous::Enum::BorderStyle> for the styles.

=back

=head2 Border space

Clay, the layout engine, would draw borders on top of the content. This
role prevents that: every drawn side (see L</drawn_border_sides>) adds
one cell to that side's padding before Clay lays the widget out. The
effect is:

=over

=item * The content starts inside the border, and the C<padding> in the
widget's C<layout> is extra space between the border and the content.
In the SYNOPSIS, a child of the box starts two cells right of the left
edge: one for the border, one for the padding.

=item * A widget with C<fit> sizing grows by the border.

=item * A C<Hidden> side adds no padding, so the content reaches that
edge of the widget.

=back

Room between the border and the content is C<padding>, never a
thicker border. The widget's stored C<layout> is not modified; only the
configuration handed to Clay is.

=head1 CONSTRUCTOR PARAMETERS

These parameters are accepted by the C<new> of every widget class that
composes the role. Unknown values die.

=over

=item C<border_style>

A L<Term::Fabulous::Enum::BorderStyle> item, for example
C<< Term::Fabulous::Enum::BorderStyle->Round >>, or its name
(C<'Round'>, case sensitive); it sets the style of every side that has
no side parameter of its own. Default: the style the theme gives the
widget's family, if any (see L<Term::Fabulous::Manual::Looks/THEMES>).
Anything else dies, listing the known names (see
L<Term::Fabulous::Check/border_style>).

=item C<border_style_top>

=item C<border_style_right>

=item C<border_style_bottom>

=item C<border_style_left>

C<undef>, a L<Term::Fabulous::Enum::BorderStyle> item or its name, for
one side. Default: C<undef>. A side parameter wins over C<border_style>:

	border_style      => Term::Fabulous::Enum::BorderStyle->Solid,
	border_style_left => Term::Fabulous::Enum::BorderStyle->Thick,

gives a thick left side and solid other sides, like
C<border style=Solid style-left=Thick> in a KDL layout file. The side
accessors change one side after construction.

=item C<border_corners>

C<undef> (the default) or a hash reference with any of the keys
C<top_left>, C<top_right>, C<bottom_left> and C<bottom_right>, each a
single character one column wide. A corner named here is drawn with
that glyph instead of the corner glyph of its style; the others keep
theirs. Only corners that are drawn at all are affected (a corner is
drawn where a drawn top or bottom side meets a drawn left or right
side). The colors stay those of the style's corner. Unknown keys and
other glyphs die. L<Term::Fabulous::Widget::Table> uses it to join the
lines of its cells, with the glyphs from
L<Term::Fabulous::Enum::BorderStyle/junction>.

	border_style   => Term::Fabulous::Enum::BorderStyle->Solid,
	border_corners => { top_left => "\x{251C}", bottom_left => "\x{251C}" },

=item C<outer_border_sides>

An array reference of side names (C<top>, C<right>, C<bottom>,
C<left>). Default: C<[]>. The glyphs of these sides are drawn on the
background just outside the widget (what is painted there, usually the
parent's background) instead of the widget's own: the border looks like
part of its surroundings, and a colored widget starts inside it. The
glyphs of a style that already uses the outer background (see
L<Term::Fabulous::Enum::BorderStyle/locations>) are not affected; those
in reverse video use the outer background as well. A corner is drawn
like the side next to it when that side is listed, otherwise like its
top or bottom side. Unknown side names die.
L<Term::Fabulous::Widget::Table> draws its outer frame this way, so a
highlighted row ends at the frame.

=back

C<border_corners> and C<outer_border_sides> cannot be set from a KDL
layout file.

=head1 METHODS

There is no C<border_style> accessor; to change all sides after
construction, call the four side accessors.

=head2 border_style_top

	my $style = $box->border_style_top;    # the style the top side is drawn in
	$box->border_style_top( Term::Fabulous::Enum::BorderStyle->Heavy );
	$box->border_style_top(undef);         # no style of its own: the theme's

Accessor for the style of the top side. The writer takes C<undef> (no
style of its own), a L<Term::Fabulous::Enum::BorderStyle> item or its
name, anything else dies, and returns the new value. The reader
returns the style the side is drawn in, as L</border_style_of>: the
side's own style, else the derived or the theme's style, else
C<Blank>; it is never C<undef>, like the color readers that return the
color in use. The change shows in the next frame.

=head2 border_style_right

	$box->border_style_right( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the right side, as L</border_style_top>.

=head2 border_style_bottom

	$box->border_style_bottom( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the bottom side, as L</border_style_top>.

=head2 border_style_left

	$box->border_style_left( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the left side, as L</border_style_top>.

=head2 border_style_of

	my $style = $widget->border_style_of('left');

The L<Term::Fabulous::Enum::BorderStyle> item a side (C<top>,
C<right>, C<bottom> or C<left>; anything else dies) is drawn in: the
style given to the side (directly or through C<border_style>), else
the one the widget derives (L</derived_border_style>), else the
theme's C<border.style> for the widget's family and classes (see
L<Term::Fabulous::Role::Themed/look>), else C<Blank>. The four side
readers and L<Term::Fabulous::Render::Border> answer with it, and a
side it answers C<Hidden> for is not drawn and takes no space (see
L</Border space>).

=head2 drawn_border_sides

	my $drawn = $widget->drawn_border_sides;    # { top => 1, right => 1, bottom => 0, left => 1 }

The sides a border is drawn on and takes a cell of: the sides of
L<Term::Fabulous::Widget/bordered> whose style (L</border_style_of>)
is not C<Hidden>. A new hash reference of all four sides, each 1 or 0.
For widgets that place parts inside their border, as
L<Term::Fabulous::Widget::ScrollBox> places its scrollbars.

=head2 border_corners

	my $corners = $box->border_corners;    # a copy, or undef
	$box->border_corners( { top_left => "\x{253C}" } );
	$box->border_corners(undef);           # the style's corners again

Accessor for the C<border_corners> parameter. The reader returns a new
hash (or C<undef>); the writer takes what the parameter takes, replaces
all corners at once and returns the new value. The change shows in the
next frame.

=head2 outer_border_sides

	my $sides = $box->outer_border_sides;          # a copy, e.g. [ 'left', 'top' ]
	$box->outer_border_sides( [ 'left', 'right' ] );

Accessor for the C<outer_border_sides> parameter. The reader returns a
new array reference of the sides in the order C<left>, C<right>,
C<top>, C<bottom>; the writer takes what the parameter takes and
returns the new value. The change shows in the next frame.

=head2 is_outer_border_side

	my $outer = $box->is_outer_border_side('left');    # 1 or 0

Whether a side is listed in C<outer_border_sides>. Used by
L<Term::Fabulous::Render::Border>.

=head2 border_corner_glyph

	my $glyph = $box->border_corner_glyph('top_left');    # or undef

The glyph drawn at one corner instead of the style's corner glyph, or
C<undef> when the style's glyph is drawn. Used by
L<Term::Fabulous::Render::Border>.

=head2 contribute_border_sides

	$widget->contribute_border_sides( \%config );

Called by Clay::UI while it builds the configuration of a frame, after
C<contribute_border>, which handed Clay the C<border_color> the program
gave: it tells Clay to draw a border one cell wide on every side of
L</drawn_border_sides> and none on the others. You do not call it
yourself.

=head2 contribute_layout_inset

	$widget->contribute_layout_inset( \%config );

Called by Clay::UI while it builds the configuration of a frame; it
adds a cell for every side of L</drawn_border_sides> to the padding as
described in L</Border space>. You do not call it yourself.

=head1 METHODS A WIDGET DEFINES

=head2 derived_border_style

	# A tab: the bar's line style, except on the side toward the page.
	method derived_border_style ($side) {
		return $side eq $page_side ? Term::Fabulous::Enum::BorderStyle->Hidden : $bar->line_style;
	}

Optional. The style a side without a style of its own is drawn in,
derived from the widget's surroundings, or C<undef> to leave the side
to the theme. Read whenever a side's style is read, so it may follow
other widgets without copying their looks.
L<Term::Fabulous::Widget::Tabs::Button> and
L<Term::Fabulous::Widget::Tabs::Page> derive their borders from the
bar, the option list of a L<Term::Fabulous::Widget::Dropdown> takes the
dropdown's C<list.border.style>. A style the program gives a side wins
over it.

=head1 SEE ALSO

L<Term::Fabulous::Enum::BorderStyle>, L<Term::Fabulous::Manual::Looks/BORDERS>,
L<Term::Fabulous::Widget>, L<Clay::UI::Role::Style::HasBorder>, the
example program F<examples/border-showcase.pl>, which shows every style.

=cut
