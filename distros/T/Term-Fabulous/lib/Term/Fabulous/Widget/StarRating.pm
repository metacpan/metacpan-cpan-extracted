package Term::Fabulous::Widget::StarRating;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Role::HasRange;
use Term::Fabulous::Widget::Input;

our $VERSION = '0.02';

class Term::Fabulous::Widget::StarRating
	:isa(Term::Fabulous::Widget::Input)
	:does(Term::Fabulous::Role::HasRange)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use List::Util ();    # max is a method here
	use Scalar::Util qw(refaddr weaken);
	use Term::Fabulous::Check qw(boolean non_negative_integer optional positive_integer);
	use Term::Fabulous::Color;
	use Term::Fabulous::Range;
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN TB_MOD_SHIFT);
	use Term::Fabulous::Unicode qw(string_columns);

	field $half        :param = 0;
	field $read_only   :param = 0;
	field $show_value  :param = 0;
	field $gap         :param = 1;
	field $full_glyph  :param = "\x{2605}";
	field $empty_glyph :param = "\x{2606}";
	field $half_glyph  :param = undef;

	field $range;    # a Term::Fabulous::Range from 0 to max, in steps of a (half) star

	# The star the pointer is over, counted from 1, while it hovers.
	field $_hover_star;

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			accent_color   => [ 'star',     'normal', 'cell_color' ],
			inactive_color => [ 'inactive', 'normal', 'cell_color' ],
			half_color     => [ 'half',     'normal', 'optional_cell_color' ],
		);
	}

	ADJUST :params ( :$max = 5, :$value_format = undef, :$value = 0 ) {
		$half        = boolean( $self, half       => $half );
		$read_only   = boolean( $self, read_only  => $read_only );
		$show_value  = boolean( $self, show_value => $show_value );
		$gap         = non_negative_integer( $self, gap => $gap );
		$full_glyph  = Term::Fabulous::Check::glyph( $self, full_glyph  => $full_glyph );
		$empty_glyph = Term::Fabulous::Check::glyph( $self, empty_glyph => $empty_glyph );
		$half_glyph  = $self->_checked_half_glyph($half_glyph);
		$range       = Term::Fabulous::Range->new(
			owner          => ref $self,
			max            => positive_integer( $self, max => $max ),
			step           => $half ? 0.5 : 1,
			paging         => 0,
			value_format   => $value_format,
			default_format => \&_stars_of,
			value          => $value,
		);

		weaken( my $weak_self = $self );
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on( MouseMove      => sub ($event) { $weak_self->_hover_at( $weak_self->_star_at($event) ) if $weak_self;                            return $continue } );
		$self->on( OnHoverStopped => sub ($event) { $weak_self->_hover_at(undef) if $weak_self && refaddr( $event->target ) == refaddr($weak_self); return $continue } );
	}

	method _checked_half_glyph ($value) {
		return optional( \&Term::Fabulous::Check::glyph, $self, half_glyph => $value );
	}

	# ---------------------------------------------------------------------
	# Value
	# ---------------------------------------------------------------------

	method value (@new) {
		return $range->value unless @new;
		$range->set_value( $new[0] );
		$self->mark_changed;
		return $range->value;
	}

	# The user moved the value: fire Change if it moved. Returns 1 when the
	# value changed.
	method _moved ($changed) {
		return 0 unless $changed;
		$self->mark_changed;
		$self->fire_change( $range->value );
		return 1;
	}

	method step () {
		return $range->step;
	}

	# The default text of a value: 3/5, or 3.5/5 with half stars.
	sub _stars_of ( $number, $range ) {
		return sprintf '%s/%d', ( $range->step < 1 ? sprintf( '%.1f', $number ) : $number ), $range->max;
	}

	method format_value ($number) {
		return $range->format_value($number);
	}

	# max and half decide the grid the value snaps to; a layout gives them
	# in one go (Term::Fabulous::Role::HasRange).
	method set_range (%parts) {
		my @unknown = grep { $_ ne 'max' && $_ ne 'half' } sort keys %parts;
		die ref($self) . ": set_range takes max and half, got @unknown" if @unknown;
		my $stars = exists $parts{max} ? positive_integer( $self, max => $parts{max} ) : $range->max;
		$half = boolean( $self, half => $parts{half} ) if exists $parts{half};
		$range->set_range( max => $stars, step => $half ? 0.5 : 1 );
		$self->mark_changed;
		return $self;
	}

	method range_properties :common () {
		return qw(max half);
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $$field_ref;
	}

	method _set_value_format ($format) {
		$range->set_value_format($format);
		$self->mark_changed;
		return $range->value_format;
	}

	method max (@new) {
		$self->set_range( max => $new[0] ) if @new;
		return $range->max;
	}

	method half (@new) {
		$self->set_range( half => $new[0] ) if @new;
		return $half;
	}

	method read_only (@new) {
		return $read_only unless @new;
		$self->_set( \$read_only, boolean( $self, read_only => $new[0] ) );
		$self->focus_eligibility_changed;    # a read-only rating gives the focus up
		return $read_only;
	}

	method show_value     (@new) { return @new ? $self->_set( \$show_value, boolean( $self, show_value => $new[0] ) )                        : $show_value }
	method value_format   (@new) { return @new ? $self->_set_value_format( $new[0] )                                                         : $range->value_format }
	method gap            (@new) { return @new ? $self->_set( \$gap, non_negative_integer( $self, gap => $new[0] ) )                         : $gap }
	method full_glyph     (@new) { return @new ? $self->_set( \$full_glyph, Term::Fabulous::Check::glyph( $self, full_glyph => $new[0] ) )   : $full_glyph }
	method empty_glyph    (@new) { return @new ? $self->_set( \$empty_glyph, Term::Fabulous::Check::glyph( $self, empty_glyph => $new[0] ) ) : $empty_glyph }
	method half_glyph     (@new) { return @new ? $self->_set( \$half_glyph, $self->_checked_half_glyph( $new[0] ) )                          : $half_glyph }
	method inactive_color (@new) { return @new ? $self->set_look( inactive_color => $new[0] )                                                : $self->look_value('inactive_color') }
	method half_color     (@new) { return @new ? $self->set_look( half_color => $new[0] )                                                    : $self->look_value('half_color') }

	# A read-only rating never takes the focus.
	method accepts_focus :override () {
		return $read_only ? 0 : $self->SUPER::accepts_focus;
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'scalar' } qw(max value value_format gap full_glyph empty_glyph half_glyph) ),
			( map { $_ => 'boolean' } qw(half read_only show_value) ),
		);
	}

	# ---------------------------------------------------------------------
	# Input
	# ---------------------------------------------------------------------

	# The star, counted from 1, under a mouse event; undef on a gap, the
	# label or outside.
	method _star_at ($event) {
		my ($column) = $self->cell_at($event);
		return undef unless defined $column;
		my $pitch = 1 + $gap;
		return undef if $column % $pitch != 0;
		my $star = $column / $pitch + 1;
		return $star <= $range->max ? $star : undef;
	}

	method _hover_at ($star) {
		return if $read_only || !$self->is_enabled;
		return if ( $star // 0 ) == ( $_hover_star // 0 );
		$_hover_star = $star;
		$self->mark_changed;
		return;
	}

	method handle_key ($event) {
		return 0 if $read_only;
		my $name = $event->main_key_name // return 0;
		if ( $name =~ /\A[0-9]\z/ ) {
			return 0 if $name > $range->max;
			$self->_moved( $range->move_to($name) );
			return 1;
		}
		my $changed = $range->move_by_key($name) // return 0;
		$self->_moved($changed);
		return 1;
	}

	method handle_mouse ($event) {
		return 0 if $read_only;
		my $key = $event->key;
		if ( $key == TB_KEY_MOUSE_WHEEL_UP || $key == TB_KEY_MOUSE_WHEEL_DOWN ) {

			# At 0 or max the notch is left to a scroll box.
			return 0 unless $self->_moved( $range->move_by( $key == TB_KEY_MOUSE_WHEEL_UP ? 1 : -1 ) );
			$event->use_wheel;
			return 1;
		}
		return 0 unless $key == TB_KEY_MOUSE_LEFT;
		my $star = $self->_star_at($event) // return 1;
		$self->_moved( $range->move_to( $half && $event->modifiers & TB_MOD_SHIFT ? $star - 0.5 : $star ) );
		return 1;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# The columns of the value label: wide enough for any value, so the
	# stars stay in place while the value changes.
	method _label_columns () {
		return 0 unless $show_value;
		return List::Util::max map { string_columns( $self->format_value($_) ) } 0, $range->max, $range->value, ( $half ? 0.5 : () );
	}

	method _stars_columns () {
		return $range->max + ( $range->max - 1 ) * $gap;
	}

	method natural_size () {
		my $label = $self->_label_columns;
		return ( $self->_stars_columns + ( $label ? $label + 1 : 0 ), 1 );
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $_hover_star // 0 );
	}

	method _half_attr () {
		return $self->color_attr( $self->disabled_color ) unless $self->is_enabled;
		my $half_color = $self->half_color;
		return $self->color_attr($half_color) if defined $half_color;
		my $accent = Term::Fabulous::Color->new( color => $self->accent_color );
		return $self->color_attr( $accent->blend( Term::Fabulous::Color->new( color => $self->inactive_color ), 0.5 ) );
	}

	method paint () {
		my $bg       = $self->paint_focus_background;
		my $shown    = $_hover_star // $range->value;
		my $full_fg  = $self->accent_attr;
		my $empty_fg = $self->color_attr( $self->is_enabled ? $self->inactive_color : $self->disabled_color );
		my $half_fg  = $self->_half_attr;

		foreach my $star ( 1 .. $range->max ) {
			my $x = ( $star - 1 ) * ( 1 + $gap );
			my ( $glyph, $fg )
				= $star <= $shown       ? ( $full_glyph, $full_fg )
				: $star - 0.5 == $shown ? ( $half_glyph // $full_glyph, $half_fg )
				:                         ( $empty_glyph, $empty_fg );
			$self->put_attrs( $x, 0, $glyph, $fg, $bg );
		}
		return unless $show_value;
		$self->paint_text( $self->_stars_columns + 1, 0, $self->format_value($shown), $self->foreground_attr, $bg );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::StarRating - Rate something with a row of stars

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::StarRating;

	my $rating = Term::Fabulous::Widget::StarRating->new(
		id         => 'rating',
		max        => 5,
		value      => 3,
		show_value => 1,
	);
	$rating->on( Change => sub ($event) {
		save_rating( $event->value );
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	say $rating->value;    # 3
	$rating->value(4);     # programmatic: fires no Change

	# Shown, not edited:
	my $stars = Term::Fabulous::Widget::StarRating->new( value => 4.5, half => 1, read_only => 1 );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-star-rating.svg" alt="Star ratings: a focused one with three of five stars, one with half stars and its value, a read-only one, one out of ten with a gap of zero, and a disabled one"></p>

=end html

=head1 DESCRIPTION

The picture shows star ratings in their forms: a focused one with three
of five stars, one with half stars that shows its value, a read-only
one, one with ten stars and no gap between them, and a disabled one.
The program is F<examples/widgets/star-rating.pl>.

A star rating shows C<max> stars (five by default), the first C<value>
of them filled, and optionally the value as text:

=for highlighter language=text

	★ ★ ★ ☆ ☆  3/5

The user chooses a value with the arrow keys, C<Home> and C<End>, the
digit keys, by clicking a star or with the mouse wheel. While the
pointer is over a star, the stars up to it are shown filled as a
preview; the value changes only with a click. With C<half> the value
moves in half stars, and a half star is drawn as the C<half_glyph> in
C<half_color>; without a glyph of its own, it is the full star in a
color halfway between the filled and the empty stars.

A read-only rating (C<read_only>) shows a value without letting the
user change it: it takes no focus, no keys and no clicks, and keeps its
colors (a disabled rating is gray). Use it in lists and cards.

Disabling, colors, focus and sizing are described in
L<Term::Fabulous::Widget::Input>. The filled stars are painted in
C<accent_color>, which defaults to a yellow for this widget, the empty
stars in C<inactive_color>. The rating is one row high and, unless the
C<layout> sizes it, as wide as its stars with their gaps and the value
label.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $rating = Term::Fabulous::Widget::StarRating->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Input/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters,
C<disabled>, C<can_focus>, C<text_color>, C<disabled_color>,
C<accent_color>, C<focus_background_color>, the other Box parameters)
and the ones below. Unknown parameters die.

=over

=item C<max>

A positive integer. Default: 5. The number of stars.

=item C<value>

A number from 0 to C<max>. Default: 0. The initial value; it is rounded
to whole stars, or to half stars with C<half>. Dies if outside the
range.

=item C<half>

A boolean. Default: 0. Whether the value moves in half stars (0.5)
instead of whole ones. Stored as 1 or 0; a reference dies.

=item C<read_only>

A boolean. Default: 0. A read-only rating shows its value and ignores
the user: it cannot take the focus, and keys, clicks and the wheel do
nothing. Unlike C<disabled>, it keeps its colors.

=item C<show_value>

A boolean. Default: 0. Whether the value is shown as text right of the
stars, formatted with C<value_format>.

=item C<value_format>

How the value is shown: a C<sprintf> format string such as C<'%.1f'>,
or a code reference that gets the value and returns the text. Default:
C<undef>, which shows C<3/5> (or C<3.5/5> with C<half>). Anything other
than a string, a code reference or C<undef> dies. The label is as wide
as the widest value, so the stars stay in place.

=item C<gap>

A non-negative integer. Default: 1. The columns between two stars.

=item C<full_glyph>

A single character one column wide. Default: C<"\x{2605}"> (black
star). A filled star.

=item C<empty_glyph>

A single character one column wide. Default: C<"\x{2606}"> (white
star). An empty star.

=item C<half_glyph>

A single character one column wide, or C<undef>. Default: C<undef>,
which draws a half star with C<full_glyph> in C<half_color>. Fonts
rarely have a half-filled star; C<"\x{2BEA}"> (star with left half
black) is one where they do.

=item C<inactive_color>

The color of the empty stars, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<input.inactive>, C<[90, 96, 110, 255]> in the dark theme, a gray.

=item C<half_color>

The color of a half star, or C<undef>. Default: the theme's
C<input.half>, none in the built-in themes: a color halfway between
C<accent_color> and C<inactive_color>.

=item C<accent_color>

As for every input, but it comes from the theme's C<input.star>,
C<[229, 192, 123, 255]> in the dark theme, a yellow, when it is not
given.

=back

The glyph parameters die unless they are exactly one grapheme cluster
one column wide.

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Input/METHODS> (C<disabled>,
C<is_enabled>, the color accessors, C<mark_changed>), plus:

=head2 value

	my $stars = $rating->value;
	$rating->value(4);

Accessor. Returns the current value, a number. Writing rounds the new
value to whole or half stars, marks the input changed, and returns the
stored value. Dies if the new value is not a finite number in
C<0..max>. Writing fires no C<Change> event.

=head2 max

	my $stars = $rating->max;
	$rating->max(10);

Accessor for the number of stars. Writing moves the value into the new
range if needed (without a C<Change> event), marks the input changed
and returns the new C<max>. Dies unless it is a positive integer.

=head2 half

	$rating->half(1);

Accessor for the C<half> parameter. Writing rounds the value to the new
grid (without a C<Change> event) and returns 1 or 0.

=head2 set_range

	$rating->set_range( max => 10, half => 1 );

Changes C<max> and C<half> together, as a layout does (see
L<Term::Fabulous::Role::HasRange>): the value moves onto the new grid
without a C<Change> event. Unknown parts die. Returns the rating.

=head2 step

	my $step = $rating->step;    # 1, or 0.5 with half

How far one key press or wheel notch moves the value. Read-only.

=head2 read_only

	$rating->read_only(1);

Accessor for the C<read_only> parameter. Writing a true value takes
the focus away from the rating if it has it; writing a false value
lets it take the focus again. Returns 1 or 0.

=head2 show_value

	$rating->show_value(1);

Accessor for the C<show_value> parameter. Returns 1 or 0.

=head2 value_format

	$rating->value_format('%.1f stars');

Accessor for the C<value_format> parameter. Anything other than a
string, a code reference or C<undef> dies and leaves the old format.

=head2 format_value

	my $text = $rating->format_value(3.5);

A number formatted as the rating shows it (see C<value_format>).

=head2 gap

	$rating->gap(0);

Accessor for the C<gap> parameter; the new width takes effect at the
next frame.

=head2 full_glyph

	$rating->full_glyph('*');

Accessor for the C<full_glyph> parameter. A value that is not a single
one-column character dies and leaves the old glyph.

=head2 empty_glyph

	$rating->empty_glyph('.');

Accessor for the C<empty_glyph> parameter; works like L</full_glyph>.

=head2 half_glyph

	$rating->half_glyph("\x{2BEA}");
	$rating->half_glyph(undef);

Accessor for the C<half_glyph> parameter; C<undef> returns to the full
glyph in C<half_color>.

=head2 inactive_color

	$rating->inactive_color('#444444');

Accessor for the C<inactive_color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 half_color

	$rating->half_color('#a08040');
	$rating->half_color(undef);

Accessor for the C<half_color> parameter; C<undef> returns to the
computed color.

Every writer marks the input changed, so the next frame paints the new
look.

=head1 KEYS

While the rating has the focus, is enabled and not read-only:

=over

=item C<Left>, C<Down>

One star (or half star) less.

=item C<Right>, C<Up>

One star (or half star) more.

=item C<Home>

No stars (0).

=item C<End>

All stars (C<max>).

=item C<0> to C<9>

That many stars, when the digit is not more than C<max>.

=back

The value never leaves C<0..max>; at either end these keys do nothing
(but are still used). All other keys, and digits above C<max>, bubble
to the ancestors.

=head1 MOUSE

=over

=item Hover

While the pointer is over a star, the stars up to it are shown filled
(and the value label shows that value) as a preview of a click. The
preview goes when the pointer leaves the widget. A read-only or
disabled rating shows no preview. The terminal reports pointer motion
only while the program runs with the mouse enabled.

=item Click

A click on a star sets the value to that star. With C<half>, a click
with C<Shift> held sets it to half a star less (Shift+click on the
third star gives 2.5). Clicks on the gaps and the value label do
nothing but focus the rating.

=item Wheel

Each notch moves the value by one step: up increases, down decreases.
A notch that cannot move the value (down at 0, up at C<max>) is not
used: inside a L<Term::Fabulous::Widget::ScrollBox> it scrolls the
scroll box instead.

=back

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change> whenever the user moves the value to
a different number of stars; C<< $event->value >> is the new number.
Programmatic writes to C<value>, C<max> and C<half> fire nothing.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Input/KDL PROPERTIES>, plus
C<max>, C<value>, C<gap>, C<value_format> (a format string only; code
references cannot be written in KDL), C<full_glyph>, C<empty_glyph>,
C<half_glyph>, C<half>, C<read_only> and C<show_value> (C<#true> /
C<#false>), and C<inactive_color> and C<half_color> (color strings):

=for highlighter language=kdl

	use Term::Fabulous::Widget::StarRating as StarRating

	StarRating "rating" {
		max 5
		half #true
		value 3.5
		show_value #true
	}

C<max> and C<half> are applied before C<value>, so they may come in any
order.

=head1 EXAMPLES

=head2 A rating in a list

=for highlighter language=perl

	my $stars = Term::Fabulous::Widget::StarRating->new( value => 4, read_only => 1, gap => 0 );

=head2 Words instead of numbers

	my @words  = qw(unrated poor fair good very_good excellent);
	my $rating = Term::Fabulous::Widget::StarRating->new(
		show_value   => 1,
		value_format => sub ($stars) { $words[$stars] =~ tr/_/ /r },
	);

=head1 SEE ALSO

L<Term::Fabulous::Widget::Input>, L<Term::Fabulous::Event::Change>,
L<the star rating section of the forms guide|Term::Fabulous::Manual::Forms/Star ratings>.

=cut
