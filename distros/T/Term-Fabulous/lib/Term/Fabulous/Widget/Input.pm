package Term::Fabulous::Widget::Input;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Disableable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Pressable;
use Term::Fabulous::Role::Validatable;
use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Input
	:isa(Term::Fabulous::Widget::Display)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Disableable)
	:does(Term::Fabulous::Role::Validatable)
	:abstract
{
	use Clay::UI::Enum::Result;
	use Scalar::Util qw(refaddr weaken);
	use Term::Fabulous::Termbox qw(TB_REVERSE);
	use Term::Fabulous::Color;
	use Term::Fabulous::Event::Change;

	ADJUST {
		weaken( my $weak_self = $self );
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		my $own      = sub ($event) { defined $weak_self && refaddr( $event->target ) == refaddr($weak_self) };

		$self->on( OnFocus  => sub ($event) { $weak_self->focus_changed(1) if $own->($event); return $continue } );
		$self->on( OnBlur   => sub ($event) { $weak_self->focus_changed(0) if $own->($event); return $continue } );
		$self->on( KeyPress => sub ($event) { return $weak_self->_dispatch( handle_key   => $event ) } );
		$self->on( Mouse    => sub ($event) { return $weak_self->_dispatch( handle_mouse => $event ) } );
		$self->on(
			OnRelease => sub ($event) {
				$weak_self->activate if $own->($event) && $weak_self->is_enabled;
				return $continue;
			}
		);
	}

	# ---------------------------------------------------------------------
	# Colors: anything Term::Fabulous::Widget::Canvas accepts for a cell,
	# kept as [r, g, b, a]; the theme's input family supplies the rest
	# ---------------------------------------------------------------------

	method theme_family :common () {
		return 'input';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			text_color             => [ 'text',       'normal',   'cell_color' ],
			disabled_color         => [ 'text',       'disabled', 'cell_color' ],
			invalid_color          => [ 'text',       'invalid',  'cell_color' ],
			accent_color           => [ 'accent',     'normal',   'cell_color' ],
			focus_background_color => [ 'background', 'focused',  'cell_color' ],
		);
	}

	# A disabled input is neither focused nor hovered; an invalid value
	# shows over the focus.
	method look_state :override () {
		return 'disabled' unless $self->is_enabled;
		return 'invalid' unless $self->is_valid;
		return $self->is_focused ? 'focused' : $self->is_hovered ? 'hovered' : 'normal';
	}

	# The focus background is painted inside the content, not on the
	# widget's box, so only the border follows the state here.
	method contribute_look_theme :override ($config) {
		my $background = $config->{background_color} // $self->look('background');
		$config->{background_color} = $background if defined $background;

		my $border = $config->{border} // return;
		my $color  = $self->themed_value( 'border.color', $self->look_state, $border->{color} // $self->look('border.color') );
		$config->{border} = { %$border, color => $color } if defined $color;
		return;
	}

	method text_color (@new) {
		return @new ? $self->set_look( text_color => $new[0] ) : $self->look_value('text_color');
	}

	method disabled_color (@new) {
		return @new ? $self->set_look( disabled_color => $new[0] ) : $self->look_value('disabled_color');
	}

	method invalid_color (@new) {
		return @new ? $self->set_look( invalid_color => $new[0] ) : $self->look_value('invalid_color');
	}

	method accent_color (@new) {
		return @new ? $self->set_look( accent_color => $new[0] ) : $self->look_value('accent_color');
	}

	method focus_background_color (@new) {
		return @new ? $self->set_look( focus_background_color => $new[0] ) : $self->look_value('focus_background_color');
	}

	# The attribute for normal text: the text color, or the disabled or
	# the invalid color.
	method foreground_attr () {
		my $name = !$self->is_enabled ? 'disabled_color' : !$self->is_valid ? 'invalid_color' : 'text_color';
		return $self->color_attr( $self->look_value($name) );
	}

	method accent_attr () {
		return $self->color_attr( $self->look_value( $self->is_enabled ? 'accent_color' : 'disabled_color' ) );
	}

	method reverse_attr ($attr) {
		return ( $attr // 0 ) | TB_REVERSE;
	}

	# A color as the [r, g, b, a] that Clay takes for backgrounds and
	# borders. A packed 0xRRGGBB integer is opaque.
	method rgba_of ($color) {
		return [ ( $color >> 16 ) & 0xFF, ( $color >> 8 ) & 0xFF, $color & 0xFF, 255 ] if !ref $color && $color =~ /\A[0-9]+\z/;
		return [ Term::Fabulous::Color->new( color => $color )->to_rgba ];
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# What paint reads, besides the size and the widget's own state: what
	# other objects decide, the focus, whether the widget is enabled and
	# whether its value is valid.
	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->is_focused, $self->is_enabled, $self->is_valid );
	}

	method focus_changed ($is_focused) {
		return;
	}

	# The background of the content while the input shows the focus,
	# otherwise undef: the widget's own background shows.
	method focus_background_attr () {
		return $self->is_focused ? $self->color_attr( $self->look_value('focus_background_color') ) : undef;
	}

	# Paints the focus background under the whole buffer, when there is one,
	# and returns it.
	method paint_focus_background () {
		my $bg = $self->focus_background_attr // return undef;
		$self->fill_attrs( 0, $_, $self->columns, ' ', undef, $bg ) foreach 0 .. $self->rows - 1;
		return $bg;
	}

	# ---------------------------------------------------------------------
	# Input
	# ---------------------------------------------------------------------

	# Disabled widgets ignore input; a handler returns true when it used the
	# event, which then stops bubbling.
	method _dispatch ( $handler, $event ) {
		my $result = Clay::UI::Enum::Result->CONTINUE;
		return $result unless $self->is_enabled && $self->$handler($event);
		return Clay::UI::Enum::Result->HANDLED;
	}

	method handle_key ($event) {
		return 0;
	}

	method handle_mouse ($event) {
		return 0;
	}

	# A click: the left button pressed and released over the widget.
	method activate () {
		return;
	}

	# The value the input holds, which validation reads. An input without
	# a value of its own (a list that only navigates) has none: it counts
	# as empty and is valid unless it is required.
	method value () {
		return undef;
	}

	# Fires Change, then ValidityChange when the message changed with it.
	method fire_change ($value) {
		$self->fire_event( Term::Fabulous::Event::Change->new( value => $value ) );
		$self->validate;
		return;
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			can_focus        => 'boolean',
			disabled         => 'boolean',
			required         => 'boolean',
			required_message => 'scalar',
			validator        => 'scalar',
		);
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Input - Common base class of the input widgets

=head1 SYNOPSIS

	use Term::Fabulous::Widget::TextField;

	# Every input widget accepts these parameters:
	my $field = Term::Fabulous::Widget::TextField->new(
		id                     => 'name',
		disabled               => 0,
		required               => 1,
		validator              => 'email',
		text_color             => '#dcdfe4',
		accent_color           => [ 97, 175, 239, 255 ],
		disabled_color         => 0x6c7078,
		invalid_color          => 'Tomato',
		focus_background_color => 'rgb(52, 58, 72)',
	);

	$field->disabled(1);                   # gray, ignores input, loses the focus
	$field->accent_color('#ff8800');      # shows in the next frame
	my $message = $field->error;           # what is wrong with the value, or undef
	$field->on( ValidityChange => sub ($event) { $hint->text( $event->error // '' ); return } );

	# A widget of your own (see SUBCLASS INTERFACE):
	use Object::Pad;
	use Term::Fabulous::Widget::Input;

	class My::Toggle :isa(Term::Fabulous::Widget::Input) :strict(params) {
		field $on = 0;

		method value () { return $on }

		method natural_size () { return ( 5, 1 ) }    # columns, rows

		method paint () {
			my $bg = $self->paint_focus_background;
			$self->paint_text( 0, 0, $on ? '[ON]' : '[OFF]', $self->accent_attr, $bg );
			return;
		}

		method activate () {                       # a click
			$on = $on ? 0 : 1;
			$self->mark_changed;                    # the next frame paints it
			$self->fire_change($on);
			return;
		}

		method handle_key ($event) {
			return 0 unless ( $event->main_key_name // '' ) eq 'Space';
			$self->activate;
			return 1;                               # used: stops bubbling
		}
	}

=head1 DESCRIPTION

C<Term::Fabulous::Widget::Input> is the abstract base class of all
input widgets:

=over

=item *

L<Term::Fabulous::Widget::TextField> - one line of text

=item *

L<Term::Fabulous::Widget::TextArea> - several lines of text

=item *

L<Term::Fabulous::Widget::Checkbox> - a box to check

=item *

L<Term::Fabulous::Widget::RadioButton> - one choice of a
L<Term::Fabulous::Widget::RadioGroup>

=item *

L<Term::Fabulous::Widget::Dropdown> - one choice from a list that opens

=item *

L<Term::Fabulous::Widget::Slider> - a number from a range

=item *

L<Term::Fabulous::Widget::StarRating> - a number of stars

=item *

L<Term::Fabulous::Widget::SegmentedControl> - one choice of a few,
side by side

=back

You do not create an C<Input> directly (the class is abstract and
C<new> dies); this page describes what all input widgets have in
common, and how to write an input widget of your own.

What every input widget does:

=over

=item *

It takes the keyboard focus. Under L<Term::Fabulous>, C<Tab> and
C<BackTab> (Shift+Tab) move the focus from input to input, and a click on an
input focuses it. The focused input shows its content on
C<focus_background_color>. A radio button is the exception: its radio
group takes the focus for all its buttons.

=item *

It receives the key presses while it has the focus. Keys it uses (for
example letters in a text field) stop there; keys it does not use (for
example C<Escape>, C<Tab> or C<F1>) bubble on to its ancestors, so
application shortcuts on an outer box keep working while the user types.
Each widget's KEYS section lists the keys it uses. See
L<Term::Fabulous::Manual::Events/KEYBOARD>.

=item *

It works with the mouse: clicks, drags and the mouse wheel, as described
in each widget's MOUSE section. L<Term::Fabulous> asks the terminal to
report the pointer as it moves, too, so the hover state of an input
(C<is_hovered>, the C<OnHoverStart> and C<OnHoverStopped> events)
follows the pointer. A terminal that does not report plain movement
changes the hover state only when a button is pressed or released,
while it is dragged and when the wheel turns.

=item *

It fires a L<Term::Fabulous::Event::Change> when the user changes its
value (see L</EVENTS>).

=item *

It can check its value: C<required> rejects an empty value,
C<validator> a wrong one. An invalid value is drawn in the invalid look
and reported by L</error>, L</is_valid> and the C<ValidityChange> event
(see L</Invalid values>).

=item *

It sizes itself to its content unless the C<layout> says otherwise (see
L</SIZE>).

=item *

It can be disabled (see L</disabled>).

=item *

It has the derived states C<focused>, C<hovered>, C<pressed> and
C<disabled>, which C<< $input->has_state('focused') >> and
C<< $input->states >> report (see L<Term::Fabulous::Widget/has_state>).
Whether the value is valid is not one of these states; ask
L</is_valid>.

=item *

It can be built from a KDL layout file (see L</KDL PROPERTIES>).

=back

Technically, an input is a L<Term::Fabulous::Widget::Display>, a
canvas that paints itself when a frame is drawn (see L</Painting>):
setters only record the new state, and the frame paints whatever
changed since the last one, so only cells that really changed are sent
to the terminal. Anything you draw into an input with the canvas
methods (C<put>, C<put_text>, ...) is lost the next time it paints.

=head2 Painting

Every setter of an input records the new value and calls
C<mark_changed> (L<Clay::UI::Role::Core::Element/mark_changed>), so a
frame becomes due; nothing is painted at once. When the frame is drawn,
the renderer calls the input's C<refresh>
(L<Term::Fabulous::Widget::Canvas/refresh>), which compares the input's
I<paint key> (see L</paint_key>) with the one it last painted for: the
size of its buffer, how often the input was marked changed, whether it
has the focus, whether it is enabled, whether its value is valid, and
what a subclass adds, such as the state of its radio group. Only when
the key differs does it
clear the buffer and call L</paint>. So the cells always show the state
of the frame they are drawn in, also when the state was changed by
another widget, and a frame that changes nothing about an input paints
nothing of it. The cells read with C<cell> show the state of the last
frame. This is how every L<Term::Fabulous::Widget::Display> paints; see
L<Term::Fabulous::Widget::Display/Painting>.

=head2 Invalid values

An input's value is invalid while it is empty and the input is
C<required>, or while its C<validator> rejects it (see L</required>
and L</validator>). An invalid input looks different as soon as its
value is invalid, without waiting for the user to leave it:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-input-validation.svg" alt="Eleven inputs: a focused e-mail field with ada@exa in red, a valid address in white, ada@ in red without and with a red border, an empty required field that looks normal and one whose border is red, a red unchecked check box, a dropdown showing its gray placeholder, ada@ in purple, ada@ in yellow with a yellow border, and a disabled field in gray"></p>

=end html

The picture shows F<examples/widgets/input-validation.pl> in the dark
theme. From the top:

=over

=item *

B<Typing, focused>: an e-mail field after typing C<ada@exa>. The look
changes with every key, so the text stays red until the address is
complete. The cursor takes the color of the text.

=item *

B<Valid>, B<invalid>: the text of an invalid value is drawn in
C<invalid_color>, by default the theme's C<danger> red.

=item *

B<Invalid, border>: an input with a border (C<< bordered => 1 >>)
also draws its border in the C<danger> red, unless it was given a
C<border_color> of its own.

=item *

B<Required, empty>: an empty text field shows its placeholder in the
usual gray, required or not. So a required field without a border does
not look invalid while it is empty, only when the user types something
wrong. With a border, the border is red.

=item *

B<Required check box>: an unchecked required box draws its box and its
label in C<invalid_color>.

=item *

B<Required dropdown>: a dropdown without a choice shows its
placeholder in gray, like an empty text field.

=item *

B<invalid_color>: the color of an invalid value set for one input,
here C<'#c678dd'>, a purple.

=item *

B<Theme variant>: a theme can draw invalid values in other colors, for
every input or only for the inputs with a class. The program's theme
draws the text inputs of the class C<calm> in the C<warning> color:

	my $theme = Term::Fabulous::Theme->new(
		name     => 'calm-invalid',
		extends  => 'dark',
		variants => { 'text_input.calm' => { 'text.invalid' => 'warning', 'border.color.invalid' => 'warning' } },
	);
	my $field = Term::Fabulous::Widget::TextField->new( validator => 'email', classes => ['calm'] );

The slots are C<text> and C<border.color> in the state C<invalid>. They
belong to the family C<input>, which the families C<text_input> (text
fields and text areas) and C<dropdown> extend; a variant names the
family of the widget, as C<text_input.calm> does. To change every
input, set the slots C<input.text.invalid> and
C<input.border.color.invalid> instead. See L<Term::Fabulous::Theme>.

=item *

B<Disabled>: a disabled input shows the disabled look, valid or not.

=back

The input does not draw the message that says what is wrong. Read it
from L</error> or from the C<ValidityChange> event, and show it where it
suits your program; the recipes
L<Term::Fabulous::Cookbook::Forms/Check the values of a form (required, validator)>
and
L<Term::Fabulous::Cookbook::Forms/Write your own checks and restrict typing (accept, pattern, code)>
show two ways.

=head1 CONSTRUCTOR

=head2 new

	my $input = Term::Fabulous::Widget::TextField->new(%parameters);    # or any other input

Every input widget's C<new> accepts the parameters below, in addition to
its own. Unknown parameters die. C<Term::Fabulous::Widget::Input>
itself is abstract: calling C<< Term::Fabulous::Widget::Input->new >>
dies.

=over

=item C<id>

A string. Optional. Identifies the widget for Clay, which needs a unique
id per widget; it is also handy for telling inputs apart in a form-wide
C<Change> listener (C<< $event->target->id >>). Ids must be unique in a
widget tree.

=item C<layout>

A hash reference of layout options, as for every widget: C<sizing>,
C<padding>, C<child_gap>, C<child_alignment>, C<layout_direction>. See
L<Term::Fabulous::Manual::Layout/LAYOUT>. A C<sizing> you give here overrides
the natural size of the input on that axis (see L</SIZE>).

=item C<background_color>

The widget's background, in any format L<Term::Fabulous::Color> accepts
(see L<Term::Fabulous::Manual::Looks/Color formats>); it is stored as an
C<[r, g, b, a]> array reference. Text inputs and the dropdown
default to a dark gray (C<[36, 40, 48, 255]>); the other inputs have no
background of their own and show the background of their parent.

=item C<bordered>

=item C<border_color>

=item C<border_style>

A border around the input, exactly as for
L<Term::Fabulous::Widget::Box>; see L<Term::Fabulous::Manual::Looks/BORDERS>.
Without C<bordered>, the theme's C<border.enabled> for the input's
family decides (C<input>, C<text_input> or C<dropdown>; C<false> in
the built-in themes, so inputs have no border).
The border takes cells inside the widget's box; the natural size is
grown accordingly.

=item C<disabled>

A boolean, stored as 1 or 0. Default: 0. A disabled input is painted in
C<disabled_color>, ignores keys, clicks and the mouse wheel, and cannot
take the focus; since the user cannot change it, it fires no C<Change>
or C<Submit> of its own accord. See L</disabled>.

=item C<can_focus>

A boolean. Default: 1. Whether the input may take the keyboard focus
(see L<Clay::UI::Role::Interaction::Focusable>). It counts while the
input is enabled: a disabled input cannot take the focus, whatever this
says (see L</can_focus>). A L<Term::Fabulous::Widget::RadioButton> never
takes the focus (it does not accept it, see L</accepts_focus>), so for
it the parameter has no effect.

=item C<required>

A boolean, stored as 1 or 0. Default: 0. Whether an empty value is
invalid: empty text, a dropdown without a selection, an unchecked
checkbox (see L</value_is_empty>). See L</required>.

=item C<required_message>

A string. Default: C<'Please fill in this field.'>. What L</error>
reports for an empty required value.

=item C<validator>

What checks a non-empty value: the name of a named validator
(C<'email'>, C<'integer'>, C<'number'>, C<'url'>, C<'hostname'>,
C<'ip'>, C<'date'>, C<'time'>), a regular expression the whole value
must match, a code reference that returns what is wrong with the value
(or false), a list of those, or a L<Term::Fabulous::Validator> for one
with options. Default: C<undef>, any value is fine. See L</validator>.

=item C<text_color>

The color of the input's text. Default: the theme's C<input.text>,
C<[220, 223, 228, 255]> in the dark theme, a light gray.

=item C<disabled_color>

The color of all text while the input is disabled, and of inactive parts
such as scrollbar tracks. Default: the theme's C<input.text> in the
C<disabled> state, C<[108, 112, 120, 255]> in the dark theme, a
medium gray.

=item C<invalid_color>

The color of the text while the value is invalid (see L</is_valid>).
Default: the theme's C<input.text> in the C<invalid> state, the
C<danger> token, C<[224, 108, 117, 255]> in the dark theme, a red. The
border of an invalid input takes C<input.border.color> in the
C<invalid> state, the same red, unless the input has a
C<border_color> of its own.

=item C<accent_color>

The color of highlights: check marks, the selected radio button's mark,
the filled part of a slider, the dropdown's arrow and the border of its
open list. Default: the theme's C<input.accent>, C<[97, 175, 239, 255]>
in the dark theme, a light blue.

=item C<focus_background_color>

The background of the input's content while it has the focus. Default:
the theme's C<input.background> in the C<focused> state,
C<[52, 58, 72, 255]> in the dark theme, a dark blue-gray.

The five colors return to the theme with
L<Term::Fabulous::Widget/reset_look>; the input's own
C<background_color>, C<border_color> and border style come from the
theme's C<input> family too when they are not given. See
L<Term::Fabulous::Manual::Looks/THEMES>.

=back

The five colors accept every color format of the canvas: a packed
C<0xRRGGBB> integer, an C<[r, g, b]> or C<[r, g, b, a]> array reference,
a C<{ r, g, b }> hash reference, a string such as C<'#ff8800'>,
C<'rgb(255, 136, 0)'> or C<'hsl(32, 100%, 50%)'>, or a
L<Term::Fabulous::Color> object (see
L<Term::Fabulous::Widget::Canvas/Colors>). C<undef> and invalid colors
die. A color with alpha 0 means "no color": the terminal's default color
is used.

An input is a L<Term::Fabulous::Widget::Box>, so it also takes the
other parameters of a Box, described in L<Term::Fabulous::Widget/new>:
C<floating>, C<width_group> and C<height_group> (to line up the inputs
of a form), C<classes>, C<glyphs_show_through>, the per-side border
styles (C<border_style_top> and so on), C<border_corners> and
C<outer_border_sides>.

=head1 METHODS

=head2 disabled

	my $is_disabled = $input->disabled;
	$input->disabled(1);
	$input->disabled(0);

Accessor, from L<Clay::UI::Role::Interaction::Disableable>. Returns 1
or 0; any plain true or false value may be written, also through
C<new>; a reference dies (C<Clay::UI: 'disabled' must be a plain boolean
value>).

Writing a true value disables the input: it is painted in
C<disabled_color>, ignores keys, clicks and the mouse wheel (so the user
causes no C<Change> or C<Submit>), cannot take the focus (C<can_focus>
reads 0) and, if it has the focus, gives the focus up at once (no widget is focused afterwards,
unless the input is inside an open L<Term::Fabulous::Widget::Dialog>,
whose backdrop takes it). Clay::UI never presses a disabled widget: a
click on it fires no C<OnPress> or C<OnRelease>. C<KeyPress> and
C<Mouse> events fired on a disabled input still bubble on to its
ancestors, and it is still hovered (C<OnHoverStart>,
C<OnHoverStopped>), so listeners you add yourself for these still run.
It has the derived state C<disabled>
(L<Clay::UI::Role::Style::HasStates/DERIVED STATES>).

Writing a false value enables the input again: it can take the focus
when C<can_focus> was last set to a true value, through C<new>, a
layout file or the accessor, also while the input was disabled. A
L<Term::Fabulous::Widget::RadioButton>, which never takes the focus,
keeps 0. Writing the value the input already has changes nothing.
Returns the new value (1 or 0).

A radio button also counts as disabled while its radio group is
disabled: its C<is_enabled> is then false, while its own C<disabled>
stays 0.

=head2 is_enabled

	if ( $input->is_enabled ) { ... }

True when the input accepts input, the opposite of C<disabled>.

=head2 text_color

	my $color = $input->text_color;
	$input->text_color('#ffffff');

Accessor for the C<text_color> parameter. The reader returns the color
as C<[r, g, b, a]>, whatever form it was given in (see
L<Term::Fabulous::Check/cell_color>). Writing marks the input changed and
returns the new color. An invalid color, or C<undef>, dies and leaves
the old color.

=head2 disabled_color

	$input->disabled_color([ 90, 90, 90 ]);

Accessor for the C<disabled_color> parameter; works like
L</text_color>.

=head2 invalid_color

	$input->invalid_color('#ff5555');

Accessor for the C<invalid_color> parameter; works like
L</text_color>.

=head2 required

	my $is_required = $input->required;
	$input->required(1);

Accessor for the C<required> parameter. Returns 1 or 0; a reference
dies. Writing runs L</validate>, so a C<ValidityChange> is fired when
the message changed with it.

=head2 required_message

	$input->required_message('Please enter your name.');

Accessor for the C<required_message> parameter. A value that is not a
string dies. Writing runs L</validate>.

=head2 validator

	my $validator = $input->validator;    # a Term::Fabulous::Validator, or undef
	$input->validator('email');
	$input->validator( qr/\A[A-Z]{3}\z/ );
	$input->validator( sub ($value) { $value % 2 ? 'Please enter an even number.' : undef } );
	$input->validator( [ 'hostname', qr/\.example\.com\z/ ] );
	$input->validator( Term::Fabulous::Validator->integer( min => 1, max => 65535 ) );
	$input->validator(undef);             # any value is fine

Accessor for the validator. The reader returns the
L<Term::Fabulous::Validator> object, whatever form it was given in,
or C<undef>. Writing takes everything
L<Term::Fabulous::Validator/coerce> does; an unknown name or an
unsuitable value dies and leaves the validator as it was. Writing runs
L</validate>. A text input also takes the C<accept> spec the validator
suggests, as long as it was not given one of its own (see
L<Term::Fabulous::Widget::TextInput/accept>).

=head2 error

	my $message = $input->error;

What is wrong with the value right now, or C<undef> when it is fine:
C<required_message> for an empty required value, else what the
validator says about a non-empty value. An empty value that is not
required is fine, and the validator never sees it. The value is
checked every time you ask; nothing is cached.

=head2 is_valid

	if ( $input->is_valid ) { ... }

True when L</error> is C<undef>. While it is false, the input shows
the invalid look: its text in C<invalid_color> and its border, when it
has one, in the theme's C<input.border.color> of the C<invalid> state;
L<Term::Fabulous::Role::Themed/look_state> is C<invalid>. A disabled
input shows the disabled look instead.

=head2 validate

	my $message = $input->validate;

Checks the value and returns the message, or C<undef> when the value
is fine. When the message differs from the one the input reported last,
it also fires L<Term::Fabulous::Event::ValidityChange> on the input.

The input calls it after every C<Change> and when C<required>,
C<required_message> or C<validator> is written. Call it yourself after
setting the value from the program, which fires no events.

Before its first C<ValidityChange>, an input counts as having reported
a valid value. An input that is invalid from the start, such as an
empty required field, therefore reports nothing until the user changes
it or something calls C<validate>. To show the messages of such inputs,
call C<validate> on them: once after building the form
(C<< $_->validate foreach $form->invalid_inputs >>), or when the user
sends the form. L<Term::Fabulous::Widget/invalid_inputs> lists the
inputs below a widget that are not valid, reported or not.

=head2 accent_color

	$input->accent_color(0xFF8800);

Accessor for the C<accent_color> parameter; works like L</text_color>.

=head2 focus_background_color

	$input->focus_background_color('rgb(40, 44, 60)');

Accessor for the C<focus_background_color> parameter; works like
L</text_color>.

=head2 mark_changed

	$input->mark_changed;

Marks the input changed: a frame becomes due (see
L<Clay::UI::Role::Core::Element/mark_changed>), and that frame paints
the input again from its current state and sizes it again, also when
the change was made from a timer. The setters call it, so you only need
it after changing state behind the widget's back, for example through
L<Term::Fabulous::Widget::TextInput/editor>. Returns the input.

=head2 can_focus

	$input->can_focus(0);
	if ( $input->can_focus ) { ... }

Whether the input can take the focus now: 1 when it may (the last
value written, through C<new>, a layout file or this accessor, was
true), it is enabled and it accepts the focus at all (a radio button
does not); 0 otherwise. Writing records whether the input may take the
focus and returns what reading returns now: C<can_focus(1)> on a
disabled input returns 0, and the input takes the focus once it is
enabled. The order of C<can_focus> and C<disabled> does not matter.
Writing a false value to the focused input takes the focus away at
once. From L<Clay::UI::Role::Interaction::Focusable>.

=head2 is_focused

	if ( $input->is_focused ) { ... }

True while the input has the keyboard focus. Inherited from
L<Clay::UI::Role::Interaction::Focusable>. Give an input the focus with
C<< $ui->interaction->set_focused_widget($input) >>.

=head1 SIZE

Every input has a natural content size: for example one row and as many
columns as its label needs (a checkbox), or C<preferred_columns> by one
row (a text field). When the C<layout> gives no C<sizing> for an axis,
the input is given a fixed size on that axis: its natural size plus its
padding and its border (see L<Term::Fabulous::Widget::Display/Size>).
A C<sizing> in the C<layout> always wins:

	# 20 columns wide (the default preferred_columns), one row high:
	Term::Fabulous::Widget::TextField->new;

	# As wide as the parent allows, still one row high:
	Term::Fabulous::Widget::TextField->new( layout => { sizing => { width => sizing_grow() } } );

The natural size is a C<fixed> sizing, and a C<width_group> or
C<height_group> (L<Term::Fabulous::Widget/new>) lines up C<fit> and
C<grow> sizings only. An input has no content Clay could fit, so a
plain C<fit> sizing gives it no columns at all; to line up inputs, give
each a C<fit> sizing with its natural size as the minimum:

	# Both 30 columns wide, the width of the wider one:
	Term::Fabulous::Widget::TextField->new( width_group => 1, layout => { sizing => { width => sizing_fit(20) } } );
	Term::Fabulous::Widget::TextField->new( width_group => 1, layout => { sizing => { width => sizing_fit(30) } } );

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change>, fired on the input when the user
changes its value. Setting the value from the program never fires it.
It bubbles to the input's ancestors unless a listener on the way
returns something other than C<< Clay::UI::Enum::Result->CONTINUE >>.

=item C<ValidityChange>

L<Term::Fabulous::Event::ValidityChange>, fired by L</validate> right
after a C<Change> when the message about the value changed with it:
the value became invalid, valid, or invalid for another reason. It
bubbles like C<Change>. The event carries C<is_valid> and C<error>.

=item C<OnFocus>, C<OnBlur>

L<Clay::UI::Events::OnFocus> and L<Clay::UI::Events::OnBlur>, fired by
Clay::UI when the input gains or loses the focus.

=item C<OnHoverStart>, C<OnHoverStopped>, C<OnPress>, C<OnRelease>

The pointer events of L<Clay::UI>; see L<Term::Fabulous::Manual::Events/MOUSE>.
A completed click (C<OnRelease> after a press on the same input) is what
toggles a checkbox or selects a radio button.

=item C<CanvasResize>

L<Term::Fabulous::Event::CanvasResize>, fired when the layout gives the
input a new size. The input paints itself for the new size in the same
frame.

=back

The input registers its own listeners for C<KeyPress>, C<Mouse>,
C<OnFocus>, C<OnBlur> and C<OnRelease> when it is constructed. Listeners you add with C<on> run after them, on the same
widget, and see every event, including keys the input used. Keep in mind
that your listener's return value also decides whether the event
bubbles further.

=head1 KDL PROPERTIES

In a layout file (see L<Term::Fabulous::Layout>), every input accepts
the properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>
(C<layout>, C<sizing>, C<padding>, C<border>, C<background_color>,
C<border_color>, C<bordered>, C<width_group>, C<height_group>) and
the following ones. The string after the widget name is its C<id>
(C<TextField "name"> is the C<id> C<name>).

=over

=item C<disabled>

Takes C<#true> or C<#false>, like the C<disabled> parameter.

=item C<can_focus>

Takes C<#true> or C<#false>, like the C<can_focus> parameter; with
C<disabled #true> in the same block the order does not matter.

=item C<required>

Takes C<#true> or C<#false>, like the C<required> parameter.

=item C<required_message>

A string, like the C<required_message> parameter.

=item C<validator>

The name of a named validator (C<validator "email">); a layout cannot
give a regular expression, code or options, set those from the
program. A text input applies it before its C<value>, wherever it
stands.

=item C<text_color>, C<disabled_color>, C<invalid_color>, C<accent_color>, C<focus_background_color>

Any L<Term::Fabulous::Color> string, such as C<"#ff8800"> or
C<"rgb(255, 136, 0)">.

=back

A complete layout with one disabled text field:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Box as Box
	use Term::Fabulous::Widget::TextField as TextField

	Box "form" {
		TextField "name" {
			disabled #true
			accent_color "#ff8800"
			sizing width=grow
		}
		TextField "email" {
			required #true
			validator "email"
		}
	}

Properties are applied after the widget was constructed, with the same
checks as the accessors of the same name. Values that depend on each
other are applied together, so their order in the layout does not
matter: a dropdown's C<options> come before its C<value>, a slider's
C<min>, C<max> and C<step> are one range set before its C<value>, and a
text input's C<max_length>, C<accept> and C<validator> come before its
C<value>. Everything else is applied in the order of the layout.

=head1 SUBCLASS INTERFACE

To write an input widget of your own, subclass
C<Term::Fabulous::Widget::Input> with L<Object::Pad> (see the
L</SYNOPSIS>). You must implement C<natural_size> and C<paint>; override
the other methods as needed, C<value> as soon as the input holds a
value. Paint with C<put_attrs>
(L<Term::Fabulous::Widget::Canvas/put_attrs>) and the helpers below and
those of L<Term::Fabulous::Widget::Display/SUBCLASS INTERFACE>
(C<color_attr>, C<paint_text>, C<fill_attrs>), which take termbox2
attributes (the integers returned by C<foreground_attr>, C<color_attr>
and friends) instead of colors.

Term::Fabulous draws a frame only when something changed, and the frame
paints the input (see L</Painting>). Whenever your widget changes state
that C<paint> or C<natural_size> uses, call C<< $self->mark_changed >>
and do not paint: the next frame calls C<paint>. When C<paint> also
reads state of other objects that change without telling your widget,
add that state to L</paint_key>. Without either, the change shows only
when something else makes the input paint.

=head2 natural_size

=for highlighter language=perl

	method natural_size () { return ( $columns, $rows ) }

Required. The content size the input wants when the layout does not
size it (see L</SIZE>): a number of cells per axis, or a sizing hash of
L<Clay::XS>, as described in
L<Term::Fabulous::Widget::Display/natural_size>. Called for every frame.

=head2 paint

	method paint () { ... }

Required. Draws the input into its buffer. It is called while a frame is
drawn, when the L</paint_key> changed, with a cleared buffer that has at
least one cell; use C<< $self->columns >> and C<< $self->rows >> for
its size. Cell writes made here belong to the frame being drawn and make
no further frame due.

=head2 paint_key

	method paint_key :override () {
		my $group = $self->group;
		return ( $self->SUPER::paint_key, $group->value, $group->is_focused );
	}

The list of values L</paint> depends on; the input paints again when
any of them changed since it last painted. The default holds what
L<Term::Fabulous::Widget::Display/paint_key> holds (the size of the
buffer and a count of the input's C<mark_changed> calls), whether the
input has the focus and whether it is enabled. Extend it with what
C<paint> reads from other objects, which do not mark this input
changed: L<Term::Fabulous::Widget::RadioButton> adds its group's value,
focus and cursor button, L<Term::Fabulous::Widget::TextInput> its
editor's revision. The values are compared as strings; keep them cheap
to compute, since the key is computed for every frame.

=head2 handle_key

	method handle_key ($event) { return $used }

Receives every L<Term::Fabulous::Event::KeyPress> fired on the input
(or bubbling up to it) while it is enabled. Return true when you used
the key: the event then stops. Return false to let it bubble on. The
default uses nothing.

=head2 handle_mouse

	method handle_mouse ($event) { return $used }

Receives every L<Term::Fabulous::Event::Mouse> fired on the input (or
bubbling up to it) while it is enabled. Return value as for
C<handle_key>. The default uses nothing.

The event carries terminal coordinates. Use
L<Term::Fabulous::Widget::Canvas/cell_at> to turn them into a cell of
the input's buffer; it returns the empty list when the pointer is
outside the buffer (on the border or padding):

	method handle_mouse ($event) {
		my ( $column, $row ) = $self->cell_at($event) or return 0;
		...
	}

=head2 activate

	method activate () { ... }

Called when the input is clicked (the left button pressed and released
over it) while it is enabled. The default does nothing.

=head2 focus_changed

	method focus_changed ($is_focused) { ... }

Called after the input gained (C<$is_focused> true) or lost the focus,
for what a widget does then besides painting (a dropdown closes its
list). The default does nothing; the focus is part of the
L</paint_key>.

=head2 layout_properties

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, on_label => 'scalar', off_label => 'scalar', on_color => 'color' );
	}

The table of the properties a KDL layout may set and how each is read
(see L<Term::Fabulous::Role::CanParseLayout/layout_properties>). To
make parameters of your widget settable from a layout file, declare it
as a class method (C<:common>), keep the inherited table through
C<< $class->SUPER::layout_properties >> and add an accessor (reader and
writer) of the same name for each new property. Every input inherits
C<can_focus> and C<disabled> (booleans) and its four colors.

=head2 accepts_focus

	method accepts_focus :override () { return 0 }

Whether the input can ever take the focus. Default: 1 (from
L<Clay::UI::Role::Interaction::Focusable>). An input that returns 0
(like L<Term::Fabulous::Widget::RadioButton>) gets C<can_focus> 0 even
when enabled.

=head2 fire_change

	$self->fire_change($new_value);

Fires a L<Term::Fabulous::Event::Change> with that value on the input,
then runs L</validate>, which fires a C<ValidityChange> when the
message about the value changed. Call it after the user changed the
value, never when the program did.

=head2 value

	method value () { return $on }

The value the input holds, read by validation (L</required>,
L</validator>, L</is_valid>) whenever it is asked. Optional: the
default returns C<undef>, so an input without a value of its own, such
as a list that only moves the reader somewhere, counts as empty and is
valid unless it is C<required>. Every input of Term::Fabulous overrides
it.

=head2 value_is_empty

	method value_is_empty :override () { return $checked ? 0 : 1 }

Whether the value counts as not filled in, which C<required> rejects
and the validator never sees. Default: C<value> is C<undef> or the
empty string. L<Term::Fabulous::Widget::Checkbox> overrides it: an
unchecked box is empty. From L<Term::Fabulous::Role::Validatable>,
which also has C<validator_changed>, the hook a text input uses to
take the validator's suggested C<accept>.

=head2 foreground_attr

	my $fg = $self->foreground_attr;

The termbox2 attribute of C<text_color>, or of C<disabled_color> while
the input is disabled, or of C<invalid_color> while its value is
invalid.

=head2 accent_attr

	my $fg = $self->accent_attr;

The termbox2 attribute of C<accent_color>, or of C<disabled_color>
while the input is disabled.

=head2 reverse_attr

	my $cursor_fg = $self->reverse_attr($fg);

An attribute in reverse video (foreground and background swapped), as
used for the text cursor. C<undef> counts as the terminal default.

=head2 rgba_of

	my $rgba = $self->rgba_of($color);

Any color the canvas accepts, as the C<[r, g, b, a]> array reference
that C<background_color> and C<border_color> take. A packed integer is
opaque.

=head2 focus_background_attr

	my $bg = $self->focus_background_attr;

The attribute of C<focus_background_color> while the input has the
focus, C<undef> otherwise. Override it to change when the focus
background is shown (L<Term::Fabulous::Widget::RadioButton> shows it
only on the button the keyboard is on).

=head2 paint_focus_background

	my $bg = $self->paint_focus_background;

Fills the whole buffer with C<focus_background_attr> when it is defined,
and returns it (C<undef> when the input shows no focus background).
Pass the result on as the background of everything you paint after it.

=head1 CAVEATS

=over

=item *

A disabled input does not use the mouse wheel; inside a
L<Term::Fabulous::Widget::ScrollBox> the wheel over it scrolls the
scroll box. So does the wheel over a text area, a slider or an open
dropdown list that cannot move any further.

=back

=head1 SEE ALSO

L<Term::Fabulous::Manual::Forms/FORMS AND INPUT WIDGETS>,
L<Term::Fabulous::Event::Change>, L<Term::Fabulous::Event::ValidityChange>,
L<Term::Fabulous::Validator>, L<Term::Fabulous::Widget::Display>,
L<Term::Fabulous::Widget::Canvas>, L<Term::Fabulous::Widget::TextInput>.

=cut
