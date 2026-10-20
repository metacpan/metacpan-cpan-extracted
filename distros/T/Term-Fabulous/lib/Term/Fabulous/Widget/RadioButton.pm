package Term::Fabulous::Widget::RadioButton;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Input;

our $VERSION = '0.05';

class Term::Fabulous::Widget::RadioButton
	:isa(Term::Fabulous::Widget::Input)
	:strict(params)
{
	use List::Util qw(first max);
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Check qw(optional string);
	use Term::Fabulous::Unicode qw(string_columns);

	field $label           :param = '';
	field $value           :param = undef;
	field $selected_mark   :param = "(\x{2022})";
	field $unselected_mark :param = '( )';

	ADJUST {
		$label           = string( $self, label           => $label );
		$selected_mark   = string( $self, selected_mark   => $selected_mark );
		$unselected_mark = string( $self, unselected_mark => $unselected_mark );
		$value           = string( $self, value           => $value ) if defined $value;
	}

	method _set_string ( $name, $field_ref, @new ) {
		return $$field_ref unless @new;
		$$field_ref = string( $self, $name => $new[0] );
		$self->mark_changed;
		return $$field_ref;
	}

	method label           (@new) { return $self->_set_string( label           => \$label,           @new ) }
	method selected_mark   (@new) { return $self->_set_string( selected_mark   => \$selected_mark,   @new ) }
	method unselected_mark (@new) { return $self->_set_string( unselected_mark => \$unselected_mark, @new ) }

	# The value defaults to the label.
	method value (@new) {
		return $value // $label unless @new;
		$value = optional( \&string, $self, value => $new[0] );
		$self->mark_changed;
		return $value // $label;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, label => 'scalar', value => 'scalar', selected_mark => 'scalar', unselected_mark => 'scalar' );
	}

	# The group takes the focus for its buttons.
	method accepts_focus :override () {
		return 0;
	}

	method group () {
		return first { $_->isa('Term::Fabulous::Widget::RadioGroup') } $self->ancestors;
	}

	method is_selected () {
		my $group = $self->group;
		return defined $group && $group->holds_value( $self->value ) ? 1 : 0;
	}

	method is_enabled :override () {
		my $group = $self->group;
		return $self->SUPER::is_enabled && ( !defined $group || $group->is_enabled );
	}

	# The group decides the look as well: which button is selected, which
	# one shows the focus, and whether the buttons are enabled.
	method paint_key :override () {
		my $group  = $self->group;
		my $cursor = defined $group ? $group->cursor_button : undef;
		return (
			$self->SUPER::paint_key,
			defined $group ? ( $group->value, $group->is_focused, defined $cursor ? refaddr($cursor) : 0 ) : (),
		);
	}

	method focus_background_attr :override () {
		my $group = $self->group;
		return undef unless defined $group && $group->is_focused;
		my $cursor = $group->cursor_button;
		return undef unless defined $cursor && refaddr($cursor) == refaddr($self);
		return $self->color_attr( $self->focus_background_color );
	}

	# The columns reserved for the mark: those of the wider one, so the
	# label stays in place when the selection changes.
	method _mark_columns () {
		return max map { string_columns($_) } $selected_mark, $unselected_mark;
	}

	method natural_size () {
		return ( $self->_mark_columns + ( length $label ? 1 + string_columns($label) : 0 ), 1 );
	}

	method paint () {
		my $bg       = $self->paint_focus_background;
		my $selected = $self->is_selected;
		$self->paint_text( 0,                        0, $selected ? $selected_mark : $unselected_mark, $selected ? $self->accent_attr : $self->foreground_attr, $bg );
		$self->paint_text( $self->_mark_columns + 1, 0, $label,                                        $self->foreground_attr,                                  $bg ) if length $label;
		return;
	}

	method activate () {
		my $group = $self->group // die "Term::Fabulous::Widget::RadioButton: a radio button must be inside a Term::Fabulous::Widget::RadioGroup";
		$group->choose($self);
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::RadioButton - One choice of a radio group

=head1 SYNOPSIS

	use Term::Fabulous::Widget::RadioGroup;
	use Term::Fabulous::Widget::RadioButton;

	my $size = Term::Fabulous::Widget::RadioGroup->new( value => 'm' );
	$size->add_child(
		Term::Fabulous::Widget::RadioButton->new( label => 'Small',  value => 's' ),
		Term::Fabulous::Widget::RadioButton->new( label => 'Medium', value => 'm' ),
		Term::Fabulous::Widget::RadioButton->new( label => 'Large',  value => 'l' ),
	);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-radio.svg" alt="Radio buttons in a row with Medium chosen, in a column with Express shipping chosen, and a disabled group"></p>

=end html

=head1 DESCRIPTION

The picture shows three radio groups: one with its buttons in a row,
which has the focus (the selected button is on the
C<focus_background_color>), one in a column, and a disabled one. The
program is F<examples/widgets/radio.pl>.

A radio button is one choice of a L<Term::Fabulous::Widget::RadioGroup>.
It shows a mark and a label:

=for highlighter language=text

	(*) Medium
	( ) Large

(the selected mark is U+2022 BULLET by default, shown here as C<*>).

A radio button only works inside a radio group, as a child of the group
or deeper inside it (for example in a box that lays out several buttons
in a row). The group keeps track of which button is selected, takes the
keyboard focus for all its buttons and fires the C<Change> event; the
button itself never takes the focus and fires no C<Change>. A button is
selected when its C<value> equals the group's C<value>.

A click on a button selects it and focuses its group. Clicking a radio
button that is not inside a radio group dies.

A radio button is disabled when it or its group is disabled. Disabled
buttons are painted in C<disabled_color> and skipped by the arrow keys.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $button = Term::Fabulous::Widget::RadioButton->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Input/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters,
C<disabled>, C<text_color>, C<disabled_color>, C<accent_color>,
C<focus_background_color>, the other Box parameters) and the ones below.
C<can_focus> is accepted but has no effect: a radio button never takes
the focus. Unknown parameters die.

=over

=item C<label>

A character string. Default: C<''> (no label). The text after the mark.
Dies if not a string.

=item C<value>

A string or a number. Default: C<undef>, which means "the same as the
label". The value the group takes when this button is selected. The
buttons of one group should have different values: the group selects
every button whose value equals its own. Dies if given a reference.

=item C<selected_mark>

A character string. Default: C<"(\x{2022})">, a bullet in parentheses.
The mark of the selected button, painted in C<accent_color>.

=item C<unselected_mark>

A character string. Default: C<'( )'>. The mark of the other buttons,
painted in C<text_color>.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Input/METHODS> (C<disabled>,
C<is_enabled>, the color accessors, C<mark_changed>), plus:

=head2 value

	my $value = $button->value;
	$button->value('xl');

Accessor. Returns the button's value, or its label when no value was
given or the value was set to C<undef>. Writing marks the input changed and returns the
value as the reader would (C<< $button->value(undef) >> returns the
label). A reference dies and leaves the value unchanged. Changing the
value of the selected button does not change the group's value, so the
button is no longer selected afterwards.

=head2 label

	my $label = $button->label;
	$button->label('Extra large');

Accessor for the label. Writing marks the input changed and returns the new label. A
value that is not a string dies and leaves the label unchanged.

=head2 selected_mark

	$button->selected_mark('[*]');

Accessor for the C<selected_mark> parameter. Writing marks the input changed and returns
the new mark. A value that is not a string dies and leaves the mark
unchanged.

=head2 unselected_mark

	$button->unselected_mark('[ ]');

Accessor for the C<unselected_mark> parameter; works like
L</selected_mark>.

=head2 group

	my $group = $button->group;

The nearest L<Term::Fabulous::Widget::RadioGroup> among the button's
ancestors, or C<undef> when there is none.

=head2 is_selected

	if ( $button->is_selected ) { ... }

1 when the button's group has a value equal to the button's value
(compared as strings), 0 otherwise or when the button has no group.

=head2 is_enabled

	if ( $button->is_enabled ) { ... }

True when neither the button nor its group is disabled.

=head1 KEYS

A radio button uses no keys itself: it never has the focus. Its radio
group handles the keys; see
L<Term::Fabulous::Widget::RadioGroup/KEYS>.

=head1 MOUSE

A click (left button pressed and released over the button) selects the
button, as L<Term::Fabulous::Widget::RadioGroup/choose> does, and the
press focuses the group. Nothing happens while the button or its group
is disabled.

=head1 EVENTS

A radio button fires no C<Change> event of its own; the group fires it.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Input/KDL PROPERTIES>, plus
C<label>, C<value>, C<selected_mark> and C<unselected_mark>. Radio
buttons are written as children of a radio group; see
L<Term::Fabulous::Widget::RadioGroup/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::RadioGroup>, L<Term::Fabulous::Widget::Input>,
L<the radio button section of the forms guide|Term::Fabulous::Manual::Forms/Radio buttons>,
L<Term::Fabulous::Cookbook::Forms/Build a form from a KDL file (text fields, radio buttons, dropdown, slider, checkbox)>,
L<Term::Fabulous::Cookbook::Forms/Choose from options in Perl (Dropdown, RadioGroup, Slider)>.

=cut
