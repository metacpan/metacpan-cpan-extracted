package Term::Fabulous::Widget::TextField;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::TextInput;

our $VERSION = '0.03';

class Term::Fabulous::Widget::TextField
	:isa(Term::Fabulous::Widget::TextInput)
	:strict(params)
{
	use Term::Fabulous::Check qw(glyph optional positive_integer);
	use Term::Fabulous::Event::Submit;

	field $preferred_columns :param = 20;
	field $mask              :param = undef;

	ADJUST {
		$preferred_columns = positive_integer( $self, preferred_columns => $preferred_columns );
		$mask              = glyph( $self, mask => $mask ) if defined $mask;
	}

	method preferred_columns (@new) {
		return $preferred_columns unless @new;
		$preferred_columns = positive_integer( $self, preferred_columns => $new[0] );
		$self->mark_changed;
		return $preferred_columns;
	}

	method mask (@new) {
		return $mask unless @new;
		$mask = optional( \&glyph, $self, mask => $new[0] );
		$self->view->display_changed;    # masked text has other widths
		$self->mark_changed;
		return $mask;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, preferred_columns => 'scalar', mask => 'scalar' );
	}

	method natural_size () {
		return ( $preferred_columns, 1 );
	}

	method hides_text :override () {
		return defined $mask ? 1 : 0;
	}

	method display_cluster :override ($cluster) {
		return $mask // $self->SUPER::display_cluster($cluster);
	}

	method handle_key :override ($event) {
		return $self->SUPER::handle_key($event) unless ( $event->main_key_name // '' ) eq 'Enter';
		$self->fire_event( Term::Fabulous::Event::Submit->new( value => $self->value ) );
		return 1;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::TextField - Single-line text input

=head1 SYNOPSIS

	use Term::Fabulous::Widget::TextField;

	my $name = Term::Fabulous::Widget::TextField->new(
		id          => 'name',
		placeholder => 'Your name',
		max_length  => 40,
	);
	$name->on( Submit => sub ($event) {
		say 'Hello, ', $event->value;
		return;
	} );

	my $password = Term::Fabulous::Widget::TextField->new(
		id   => 'password',
		mask => '*',
	);

	say $name->value;    # the text, a character string

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-text-field.svg" alt="Four text fields: a focused field with Ada Lovelace typed and Lovelace selected, a placeholder, a masked password and a disabled field"></p>

=end html

=head1 DESCRIPTION

The picture shows the states of a text field: focused, with part of the
text selected (the block cursor stands on the first selected
character); empty, showing its C<placeholder>; masked for a password;
and disabled. The program is F<examples/widgets/text-field.pl>.

A text field holds one line of text that the user can type, edit, select
and copy. When the text is wider than the field, the field scrolls
sideways to keep the cursor visible: just far enough to show the
cursor's cell (the cell after the text when the cursor is at its end),
never so far that the field ends in empty cells while text is hidden on
the left, and always starting at a whole character (see
L<Term::Fabulous::TextView/Scrolling>). Line breaks never get into the
text: in pasted or assigned text they become spaces. Pressing C<Enter>
fires a L<Term::Fabulous::Event::Submit>.

The text is a Perl character string (decoded text), not UTF-8 encoded
bytes.

The editing keys, mouse selection, the placeholder, C<max_length>,
C<read_only> and the C<Change> event are the same as in the text area
and are described in L<Term::Fabulous::Widget::TextInput>. Disabling,
colors and sizing are described in L<Term::Fabulous::Widget::Input>.

=head1 CONSTRUCTOR

=head2 new

	my $field = Term::Fabulous::Widget::TextField->new(%parameters);

Accepts the parameters of
L<Term::Fabulous::Widget::TextInput/CONSTRUCTOR> (C<value>,
C<placeholder>, C<max_length>, C<read_only>, C<placeholder_color>,
C<selection_color>, C<background_color>) and of
L<Term::Fabulous::Widget::Input/CONSTRUCTOR> (C<id>, C<layout>,
C<disabled>, C<can_focus>, C<text_color>, C<disabled_color>,
C<accent_color>, C<focus_background_color>, the border parameters, the
other Box parameters), plus the two below. Unknown parameters die.

=over

=item C<preferred_columns>

A positive integer. Default: 20. The width of the text in columns when
the C<layout> gives the field no width. The field is one row high unless
the C<layout> gives it a height. Padding and border are added to these
sizes. Dies if not a positive integer.

=item C<mask>

A single character that is one column wide, or C<undef>. Default:
C<undef> (the text is shown). When set, every character of the text is
shown as this character, for passwords. C<value> and the C<Change> and
C<Submit> events still give the real text. While the mask is set, the
text cannot be copied or cut to the clipboard, and the word keys and
the double click act on the whole text, so they do not tell where its
spaces are (see L<Term::Fabulous::Widget::TextInput/KEYS>). Dies if the mask is not exactly
one grapheme cluster one column wide.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::TextInput/METHODS> (C<value>,
C<max_length>, C<placeholder>, C<read_only>, C<placeholder_color>,
C<selection_color>, C<editor>) and of
L<Term::Fabulous::Widget::Input/METHODS> (C<disabled>, C<is_enabled>,
the color accessors, C<mark_changed>), plus:

=head2 preferred_columns

	my $columns = $field->preferred_columns;
	$field->preferred_columns(30);

Accessor for the C<preferred_columns> parameter. A new value takes
effect at the next frame. Writing returns the new value. Dies if not a
positive integer; the old value then stays.

=head2 mask

	$field->mask('*');      # hide the text
	$field->mask(undef);    # show it again

Accessor for the C<mask> parameter. Writing marks the field changed and
returns the new mask. A mask that is not a single one-column character
dies; the old mask then stays.

=head1 KEYS

All keys of L<Term::Fabulous::Widget::TextInput/KEYS>, plus:

=over

=item C<Enter>

Fires L<Term::Fabulous::Event::Submit> with the text. The key is used
(it does not bubble). This also happens when the field is C<read_only>.

=back

C<Up>, C<Down>, C<PageUp> and C<PageDown> are not used by a text field
and bubble to its ancestors, as do C<Escape>, C<Tab>, the function keys
and every other key not listed in L<Term::Fabulous::Widget::TextInput/KEYS>.

=head1 MOUSE

As described in L<Term::Fabulous::Widget::TextInput/MOUSE>: click to
place the cursor, drag (while the pointer stays over the input) to
select, double-click to select a word. The mouse wheel is not used.

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change> after every change the user makes to
the text; C<< $event->value >> is the new text.

=item C<Submit>

L<Term::Fabulous::Event::Submit> when the user presses C<Enter>;
C<< $event->value >> is the text.

=back

Neither is fired for changes made by the program. Both bubble to the
ancestors (see L<Term::Fabulous::Manual::Events/Return values and bubbling>).

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::TextInput/KDL PROPERTIES>,
plus C<preferred_columns> and C<mask>:

=for highlighter language=kdl

	use Term::Fabulous::Widget::TextField as TextField

	TextField "email" {
		placeholder "name@example.com"
		preferred_columns 30
		max_length 80
	}

=head1 EXAMPLES

=head2 A search field that reacts to Enter and to typing

=for highlighter language=perl

	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow);
	use Term::Fabulous::Widget::TextField;

	my $search = Term::Fabulous::Widget::TextField->new(
		id          => 'search',
		placeholder => 'Search (Enter to run)',
		layout      => { sizing => { width => sizing_grow() } },
	);
	$search->on( Change => sub ($event) {
		show_suggestions( $event->value );
		return Clay::UI::Enum::Result->CONTINUE;
	} );
	$search->on( Submit => sub ($event) {
		run_search( $event->value );
		return;
	} );

=head2 A password field that is enabled by a checkbox

	use Term::Fabulous::Widget::Checkbox;

	my $password = Term::Fabulous::Widget::TextField->new( mask => '*', disabled => 1 );
	my $enable   = Term::Fabulous::Widget::Checkbox->new( label => 'Set a password' );
	$enable->on( Change => sub ($event) {
		$password->disabled( !$event->value );
		return;
	} );

=head2 Give the field the focus when the program starts

	my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
	$ui->interaction->set_focused_widget($name);
	$ui->run;

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextInput>, L<Term::Fabulous::Widget::TextArea>,
L<Term::Fabulous::Event::Submit>,
L<the text field section of the forms guide|Term::Fabulous::Manual::Forms/Text fields>,
L<Term::Fabulous::Cookbook::Forms/A login form (centered dialog, masked password)>.

=cut
