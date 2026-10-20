package Term::Fabulous::Widget::RadioGroup;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Disableable;
use Clay::UI::Role::Interaction::Focusable;
use Term::Fabulous::Widget::Box;

our $VERSION = '0.05';

class Term::Fabulous::Widget::RadioGroup
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Disableable)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(CLAY_TOP_TO_BOTTOM);
	use List::Util qw(first);
	use Term::Fabulous::Roving qw(roving_target);
	use Scalar::Util qw(blessed refaddr);
	use Term::Fabulous::Event::Change;

	use constant BUTTON_CLASS => 'Term::Fabulous::Widget::RadioButton';

	field $value :param = undef;

	ADJUST {
		my $layout = $self->layout;
		$self->layout( { %$layout, layout_direction => CLAY_TOP_TO_BOTTOM } ) unless exists $layout->{layout_direction};

		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on(
			KeyPress => sub ( $self, $event ) {
				return Clay::UI::Enum::Result->HANDLED if $self->is_enabled && $self->handle_key($event);
				return $continue;
			},
			owner => $self
		);
	}

	method value (@new) {
		return $value unless @new;
		$value = $new[0];
		$self->mark_changed;
		return $value;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, value => 'scalar', disabled => 'boolean', can_focus => 'boolean' );
	}

	# The radio buttons of the group in tree order: its descendants, except
	# those of nested groups.
	method buttons () {
		return grep { $_->isa(BUTTON_CLASS) && refaddr( $_->group ) == refaddr($self) } $self->descendants;
	}

	method holds_value ($candidate) {
		return defined $value && defined $candidate && $candidate eq $value;
	}

	method selected_button () {
		return first { $self->holds_value( $_->value ) } $self->buttons;
	}

	# The button the keyboard is on: the selected one, or else the first
	# enabled one.
	method cursor_button () {
		my $selected = $self->selected_button;
		return $selected if defined $selected && $selected->is_enabled;
		return first { $_->is_enabled } $self->buttons;
	}

	# Selects a button as the user does: fires Change when the value
	# changes.
	method choose ($button) {
		die "Term::Fabulous::Widget::RadioGroup: choose needs one of the group's radio buttons"
			unless blessed $button && grep { refaddr($_) == refaddr($button) } $self->buttons;
		return $self if $self->holds_value( $button->value );
		$self->value( $button->value );
		$self->fire_event( Term::Fabulous::Event::Change->new( value => $value ) );
		return $self;
	}

	method handle_key ($event) {
		my $name   = $event->main_key_name // return 0;
		my $cursor = $self->cursor_button  // return 0;

		if ( $name eq 'Space' || $name eq 'Enter' ) {
			$self->choose($cursor);
			return 1;
		}

		my @buttons = $self->buttons;
		my @enabled = grep { $buttons[$_]->is_enabled } 0 .. $#buttons;
		my $at      = first { refaddr( $buttons[$_] ) == refaddr($cursor) } 0 .. $#buttons;
		my $target  = roving_target( \@enabled, $at, $name ) // return 0;
		$self->choose( $buttons[$target] );
		return 1;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::RadioGroup - A group of radio buttons of which
one is selected

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::RadioGroup;
	use Term::Fabulous::Widget::RadioButton;

	my $size = Term::Fabulous::Widget::RadioGroup->new( id => 'size', value => 'm' );
	$size->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) )
		foreach [ Small => 's' ], [ Medium => 'm' ], [ Large => 'l' ];

	$size->on( Change => sub ($event) {
		say 'size: ', $event->value;    # 's', 'm' or 'l'
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	$size->value('l');    # programmatic: selects "Large", fires no Change

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-radio.svg" alt="Radio buttons in a row with Medium chosen, in a column with Express shipping chosen, and a disabled group"></p>

=end html

=head1 DESCRIPTION

The picture shows three radio groups: one with its buttons in a row,
which has the focus (the selected button is on the
C<focus_background_color>), one in a column, and a disabled one. The
program is F<examples/widgets/radio.pl>.

A radio group lets the user choose exactly one of several options, all
visible at once. It is a L<Term::Fabulous::Widget::Box> that holds
L<Term::Fabulous::Widget::RadioButton>s, directly or inside other boxes.
The group's C<value> is the value of the selected button; at most one
button is selected (or several, if you gave several buttons the same
value). Buttons inside a nested radio group belong to that inner group.

The group, not its buttons, takes the keyboard focus, so C<Tab> moves
past the whole group in one step, and the arrow keys move the selection.
While the group has the focus, the button the keyboard is on (the
selected one, or the first enabled one when none is selected) is painted
on C<focus_background_color>.

The buttons are laid out from top to bottom unless the C<layout> sets a
C<layout_direction>. Use C<CLAY_LEFT_TO_RIGHT> for buttons side by side:

	use Clay::XS qw(CLAY_LEFT_TO_RIGHT);

	my $size = Term::Fabulous::Widget::RadioGroup->new(
		value  => 'm',
		layout => { layout_direction => CLAY_LEFT_TO_RIGHT, child_gap => 2 },
	);

A radio group is not an L<Term::Fabulous::Widget::Input>; it has its own
C<disabled> and C<value>, and no colors (the buttons have them).

=head1 CONSTRUCTOR

=head2 new

	my $group = Term::Fabulous::Widget::RadioGroup->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box> (C<id>,
C<layout>, C<background_color>, C<bordered>, C<border_color>,
C<border_style>, ...) and the ones below. Unknown parameters die.

=over

=item C<value>

A string, a number or C<undef>. Default: C<undef> (no button selected).
The value of the button to select. A reference dies.

=item C<disabled>

A boolean. Default: 0. A disabled group cannot take the focus, ignores
keys and clicks, and all its buttons are painted in their
C<disabled_color>.

=item C<can_focus>

A boolean. Default: 1. Whether the group may take the keyboard focus.
It counts while the group is enabled: a disabled group cannot take the
focus, whatever this says (see L</can_focus>).

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Box> (C<add_child>,
C<remove_child>, C<children>, C<layout>, C<on>, ...), plus:

=head2 value

	my $value = $group->value;
	$group->value('l');
	$group->value(undef);    # select nothing

Accessor. Returns the value of the selected button, or C<undef>. Writing
selects the button(s) whose value equals the new value (compared as
strings), or no button when none has it; the next frame shows it on the
buttons. Writing fires no C<Change> event. Returns the new value. A
reference dies and leaves the value unchanged.

=head2 disabled

	my $is_disabled = $group->disabled;
	$group->disabled(1);

Accessor, from L<Clay::UI::Role::Interaction::Disableable>. Returns 1
or 0; writing returns the new value. Writing a true value disables the
group: its buttons are painted disabled, keys and clicks are ignored
(Clay::UI presses none of its buttons), C<can_focus> reads 0 and the
group gives up the focus at once if it had it. Writing a false value enables it again: it can take
the focus when C<can_focus> was last set to a true value, through
C<new>, a layout file or the accessor, also while the group was
disabled. Writing the value the group already has changes nothing.

=head2 can_focus

	$group->can_focus(0);
	if ( $group->can_focus ) { ... }

Whether the group can take the focus now: 1 when the last value
written (through C<new>, a layout file or this accessor) was true and
the group is enabled, 0 otherwise. Writing records whether the group
may take the focus and returns what reading returns now; writing a
false value to the focused group takes the focus away at once. The
order of C<can_focus> and C<disabled> does not matter. From
L<Clay::UI::Role::Interaction::Focusable>.

=head2 is_enabled

	if ( $group->is_enabled ) { ... }

True when the group is not disabled.

=head2 buttons

	my @buttons = $group->buttons;

The group's radio buttons, in tree order (top to bottom as they were
added), including buttons inside boxes in the group but not buttons
inside a nested radio group.

=head2 selected_button

	my $button = $group->selected_button;

The first button whose value equals the group's value, or C<undef>.

=head2 cursor_button

	my $button = $group->cursor_button;

The button the keyboard is on: the selected button if it is enabled,
otherwise the first enabled button, or C<undef> when there is none.

=head2 choose

	$group->choose($button);

Selects one of the group's buttons as the user does: sets the group's
value to the button's value and fires a C<Change> event, unless that
button is already selected (then nothing happens). Works even while the
group is disabled. Dies if C<$button> is not one of L</buttons>.
Returns the group.

=head2 holds_value

	if ( $group->holds_value('m') ) { ... }

True when the group's value is defined and equals the given value
(compared as strings).

=head1 KEYS

While the group has the focus and is enabled:

=over

=item C<Up>, C<Left>

Select the previous enabled button. From the first one, wrap around to
the last one. With nothing selected, the "current" button is the first
enabled one, so C<Up> selects the last.

=item C<Down>, C<Right>

Select the next enabled button, wrapping around from the last to the
first. With nothing selected, C<Down> selects the second enabled button.

=item C<Home>, C<End>

Select the first or last enabled button.

=item C<Space>, C<Enter>

Select the button the keyboard is on (see L</cursor_button>). Useful
when nothing is selected yet; on a selected button they change nothing.

=back

Each of these keys is used (it does not bubble), even when it changes
nothing. All other keys, including C<Tab>, bubble to the group's
ancestors. Disabled buttons are skipped. When the group has no enabled
button at all, every key bubbles.

=head1 MOUSE

A click on a button (left button pressed and released over it) selects
it, and the press focuses the group. Clicks are ignored while the group
or the button is disabled.

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change>, fired on the group (not on the
button) when the user selects another button, or when L</choose>
selects one; C<< $event->value >> is the new value. Writing C<value>
fires nothing.

=item C<OnFocus>, C<OnBlur>

Fired by Clay::UI when the group gains or loses the focus.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<value> (a string or number), C<disabled> and C<can_focus> (C<#true> /
C<#false>). The radio buttons are written as child nodes:

=for highlighter language=kdl

	use Term::Fabulous::Widget::RadioGroup as RadioGroup
	use Term::Fabulous::Widget::RadioButton as RadioButton

	RadioGroup "size" {
		value "m"
		layout direction=right gap=2
		RadioButton { label "Small"; value "s"; }
		RadioButton { label "Medium"; value "m"; }
		RadioButton { label "Large"; value "l"; }
	}

The C<value> may come before the buttons: it is only compared with the
buttons' values when they are painted.

=head1 EXAMPLES

=head2 Enable a text field for the choice "Other"

=for highlighter language=perl

	my $source = Term::Fabulous::Widget::RadioGroup->new( value => 'web' );
	$source->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_ ) ) foreach qw(web friend other);
	my $other = Term::Fabulous::Widget::TextField->new( disabled => 1, placeholder => 'Where?' );

	$source->on( Change => sub ($event) {
		$other->disabled( $event->value ne 'other' );
		return;
	} );

=head1 SUBCLASS INTERFACE

=head2 handle_key

	class My::RadioGroup :isa(Term::Fabulous::Widget::RadioGroup) {
		method handle_key :override ($event) {
			if ( ( $event->main_key_name // '' ) eq 'Delete' ) {
				$self->value(undef);    # clear the selection
				return 1;
			}
			return $self->SUPER::handle_key($event);
		}
	}

Called with every L<Term::Fabulous::Event::KeyPress> fired on the group
(or bubbling up to it) while the group is enabled. Returns true when it
used the key, which then stops bubbling, and false to let the key bubble
on. Override it to add keys; call C<SUPER::handle_key> for the keys
above.

=head1 SEE ALSO

L<Term::Fabulous::Widget::RadioButton>, L<Term::Fabulous::Event::Change>,
L<the radio button section of the forms guide|Term::Fabulous::Manual::Forms/Radio buttons>,
L<Term::Fabulous::Cookbook::Forms/Choose from options in Perl (Dropdown, RadioGroup, Slider)>.

=cut
