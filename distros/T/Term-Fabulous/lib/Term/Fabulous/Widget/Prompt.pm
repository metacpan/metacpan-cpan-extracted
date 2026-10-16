package Term::Fabulous::Widget::Prompt;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Dialog;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Prompt
	:isa(Term::Fabulous::Widget::Dialog)
	:strict(params)
{
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
	use List::Util qw(first max);
	use Scalar::Util qw(blessed weaken);
	use Term::Fabulous::Check qw(boolean describe optional positive_integer string);
	use Term::Fabulous::Event::Answer;
	use Term::Fabulous::Unicode qw(string_columns);
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::RichText;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	use constant DEFAULT_WIDTH => 60;
	use constant CANCEL        => 'cancel';

	field $title   :param = '';
	field $message :param = '';
	field $focus   :param = undef;
	field $check   :param = undef;

	field @_fields;    # [ { name, label, input } ], in order
	field @_buttons;    # [ { id, label, primary, widget } ], in order
	field $_title_text;
	field $_message_text;
	field $_error_text;

	# A prompt is a dialog with room around its text: two columns at the
	# sides, a row above and below, and the width the program asks for,
	# or the width of the screen when that is narrower.
	sub BUILDARGS ( $class, %params ) {
		my $width  = positive_integer( $class, width => $params{width} // DEFAULT_WIDTH );
		my $layout = $params{layout} // {};
		$params{layout} = {
			padding => { left => 2, right => 2, top => 1, bottom => 1 },
			%$layout,
			sizing => { width => sizing_grow( 0, $width ), %{ $layout->{sizing} // {} } },
		};
		return $class->SUPER::BUILDARGS(%params);
	}

	ADJUST :params ( :$fields = [], :$buttons = [ { id => 'ok', label => 'OK', primary => 1 } ], :$width = undef ) {
		$title   = string( $self, title   => $title );
		$message = string( $self, message => $message );
		die ref($self) . ": check must be a code reference or undef, got " . describe($check) if defined $check && ref $check ne 'CODE';
		@_fields  = $self->_parsed_fields($fields);
		@_buttons = $self->_parsed_buttons($buttons);
		$focus    = $self->_checked_focus($focus);

		weaken( my $weak_self = $self );
		$_title_text   = Term::Fabulous::Widget::Text->new( text => $title, bold => 1 );
		$_message_text = Term::Fabulous::Widget::RichText->new( markup => $message );
		$_error_text   = Term::Fabulous::Widget::Text->new( text => '' );
		$self->add_child($_title_text) if length $title;
		$self->add_child($_message_text) if length $message;
		$self->add_child( $self->_field_rows ) if @_fields;
		$self->add_child( $self->_button_row );

		$self->on( Submit => sub ($event) { $weak_self->answer( $weak_self->default_button ); return } );
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	method _parsed_fields ($fields) {
		die ref($self) . ": fields must be an array reference, got " . describe($fields) unless ref $fields eq 'ARRAY';
		my ( @parsed, %seen );
		foreach my $field (@$fields) {
			die ref($self) . ": a field must be a hash reference with a name and an input, got " . describe($field) unless ref $field eq 'HASH';
			my %rest  = %$field;
			my $name  = string( $self, 'the name of a field' => delete $rest{name} );
			my $label = optional( \&string, $self, "the label of the field '$name'" => delete $rest{label} );
			my $input = delete $rest{input};
			die ref($self) . ": the field '$name' needs an input widget that has a value, got " . describe($input)
				unless blessed $input && $input->can('value') && $input->isa('Term::Fabulous::Widget');
			die ref($self) . ": the field '$name' has unknown keys: " . join( ', ', sort keys %rest ) if %rest;
			die ref($self) . ": two fields are named '$name'" if $seen{$name}++;
			push @parsed, { name => $name, label => $label, input => $input };
		}
		return @parsed;
	}

	method _parsed_buttons ($buttons) {
		die ref($self) . ": buttons must be a non-empty array reference, got " . describe($buttons) unless ref $buttons eq 'ARRAY' && @$buttons;
		my ( @parsed, %seen );
		foreach my $button (@$buttons) {
			die ref($self) . ": a button must be a hash reference with an id and a label, got " . describe($button) unless ref $button eq 'HASH';
			my %rest    = %$button;
			my $id      = string( $self, 'the id of a button'            => delete $rest{id} );
			my $label   = string( $self, "the label of the button '$id'" => delete $rest{label} );
			my $primary = boolean( $self, "the primary flag of the button '$id'" => delete $rest{primary} );
			die ref($self) . ": the button '$id' has unknown keys: " . join( ', ', sort keys %rest ) if %rest;
			die ref($self) . ": two buttons have the id '$id'" if $seen{$id}++;
			push @parsed, { id => $id, label => $label, primary => $primary };
		}
		return @parsed;
	}

	# The field or button to focus when the prompt opens: a name that is
	# both is ambiguous.
	method _checked_focus ($name) {
		return undef unless defined $name;
		$name = string( $self, focus => $name );
		my $is_field  = grep { $_->{name} eq $name } @_fields;
		my $is_button = grep { $_->{id} eq $name } @_buttons;
		die ref($self) . ": focus '$name' names both a field and a button" if $is_field && $is_button;
		die ref($self) . ": focus '$name' names no field and no button" unless $is_field || $is_button;
		return $name;
	}

	# ---------------------------------------------------------------------
	# The parts
	# ---------------------------------------------------------------------

	# One row per field, the labels in a column as wide as the longest.
	method _field_rows () {
		my $label_columns = max( 0, map { string_columns( $_->{label} // '' ) } @_fields );
		my $rows          = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, child_gap => 1 } );
		foreach my $field (@_fields) {
			my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 } );
			if ($label_columns) {
				my $label = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed($label_columns) } } );
				$label->add_child( Term::Fabulous::Widget::Text->new( text => $field->{label} // '' ) );
				$row->add_child($label);
			}
			$row->add_child( $field->{input} );
			$rows->add_child($row);
		}
		return $rows;
	}

	method _button_row () {
		weaken( my $weak_self = $self );
		my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
		foreach my $button (@_buttons) {
			my $id     = $button->{id};
			my $widget = Term::Fabulous::Widget::Button->new( bordered => 1, classes => $button->{primary} ? ['primary'] : [], layout => { padding => { left => 1, right => 1 } } );
			$widget->add_child( Term::Fabulous::Widget::Text->new( text => $button->{label} ) );
			$widget->on( Activate => sub ($event) { $weak_self->answer($id); return } );
			$button->{widget} = $widget;
			$row->add_child($widget);
		}
		return $row;
	}

	# Shows what is wrong in the line above the buttons, in the color of
	# an invalid input; an empty text takes the line away.
	method _show_error ($text) {
		$_error_text->text($text);
		$_error_text->text_color( $self->family_look( input => 'text', 'invalid' ) ) if length $text;
		my $shown = $self->has_child($_error_text);
		if ( length $text && !$shown ) {
			$self->insert_children( scalar( @{ $self->children } ) - 1, $_error_text );
		}
		elsif ( !length $text && $shown ) {
			$self->remove_child($_error_text);
		}
		return;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method title (@new) {
		return $title unless @new;
		$title = string( $self, title => $new[0] );
		$_title_text->text($title);
		$self->_show_part( $_title_text, length $title, 0 );
		return $title;
	}

	method message (@new) {
		return $message unless @new;
		my $markup = string( $self, message => $new[0] );
		$_message_text->markup($markup);
		$message = $markup;
		$self->_show_part( $_message_text, length $message, $self->has_child($_title_text) ? 1 : 0 );
		return $message;
	}

	# Puts the title or the message into the prompt at its place, or takes
	# it out.
	method _show_part ( $part, $wanted, $index ) {
		my $shown = $self->has_child($part);
		$self->insert_children( $index, $part ) if $wanted && !$shown;
		$self->remove_child($part) if !$wanted && $shown;
		return;
	}

	method field_names () {
		return map { $_->{name} } @_fields;
	}

	method button_ids () {
		return map { $_->{id} } @_buttons;
	}

	method input ($name) {
		my $field = first { $_->{name} eq $name } @_fields;
		die ref($self) . ": the prompt has no field named " . describe($name) unless defined $field;
		return $field->{input};
	}

	method button ($id) {
		my $button = first { $_->{id} eq $id } @_buttons;
		die ref($self) . ": the prompt has no button with the id " . describe($id) unless defined $button;
		return $button->{widget};
	}

	method values () {
		return { map { $_->{name} => $_->{input}->value } @_fields };
	}

	# The button Enter in a text field presses: the first primary one, or
	# the first one.
	method default_button () {
		my $primary = first { $_->{primary} } @_buttons;
		return ( $primary // $_buttons[0] )->{id};
	}

	method error () {
		my $text = $_error_text->text;
		return length $text ? $text : undef;
	}

	# ---------------------------------------------------------------------
	# Opening and answering
	# ---------------------------------------------------------------------

	method open :override ($ui) {
		return $self if $self->is_open;
		$self->_show_error('');
		$self->SUPER::open($ui);
		$self->_focus_named($focus) if defined $focus;
		return $self;
	}

	method _focus_named ($name) {
		my $field = first { $_->{name} eq $name } @_fields;
		$self->_focus_into( defined $field ? $field->{input} : $self->button($name) );
		return;
	}

	# Focuses the widget, or the first focusable widget inside it when it
	# cannot take the focus itself (an input made of other inputs, such
	# as a color picker).
	method _focus_into ($widget) {
		my $interaction = $self->ui->interaction;
		my ($target) = $interaction->focusables( within => $widget );
		$interaction->set_focused_widget($target) if defined $target;
		return;
	}

	# What a button press does. A primary button checks the fields first
	# and keeps the prompt open while something is wrong.
	method answer ($id) {
		my $button = first { $_->{id} eq $id } @_buttons;
		die ref($self) . ": the prompt has no button with the id " . describe($id) unless defined $button;
		die ref($self) . ": answer needs an open prompt" unless $self->is_open;
		return $self if $button->{primary} && !$self->_values_are_fine;

		my $values = $self->values;
		$self->SUPER::close;    # the dialog's close: an answer with a button is no dismissal
		$self->fire_event( Term::Fabulous::Event::Answer->new( button => $id, values => $values ) );
		return $self;
	}

	# Checks every field, then the whole prompt; shows the first problem
	# and focuses the field it is about.
	method _values_are_fine () {
		foreach my $field (@_fields) {
			my $input = $field->{input};
			my $error = $input->can('validate') ? $input->validate : undef;
			next unless defined $error;
			$self->_show_error( ( $field->{label} // $field->{name} ) . ": $error" );
			$self->_focus_into( $self->_invalid_part_of($input) // $input );
			return 0;
		}
		my $problem = defined $check ? $check->( $self->values ) : undef;
		if ($problem) {
			$self->_show_error($problem);
			return 0;
		}
		$self->_show_error('');
		return 1;
	}

	# The first invalid input inside a field that can take the focus (a
	# color picker's text field rather than its swatch list), or undef.
	method _invalid_part_of ($input) {
		my $interaction = $self->ui->interaction;
		return first { $interaction->can_take_focus($_) } $input->invalid_inputs;
	}

	# Escape, or close from the program: the prompt answers cancel, after
	# the dialog's Close.
	method close :override () {
		return $self unless $self->is_open;
		$self->SUPER::close;
		$self->fire_event( Term::Fabulous::Event::Answer->new( button => CANCEL, values => $self->values, dismissed => 1 ) );
		return $self;
	}

	# ---------------------------------------------------------------------
	# Prompts in one call
	# ---------------------------------------------------------------------

	method alert :common ( $ui, %params ) {
		my $ok = delete $params{ok} // 'OK';
		return $class->new( %params, buttons => [ { id => 'ok', label => $ok, primary => 1 } ] )->open($ui);
	}

	method confirm :common ( $ui, %params ) {
		my $ok     = delete $params{ok}     // 'OK';
		my $cancel = delete $params{cancel} // 'Cancel';
		return $class->new( %params, buttons => [ { id => 'ok', label => $ok, primary => 1 }, { id => CANCEL, label => $cancel } ] )->open($ui);
	}

	method ask :common ( $ui, %params ) {
		my %field  = map { exists $params{$_} ? ( $_ => delete $params{$_} ) : () } qw(value placeholder required validator);
		my $label  = delete $params{label};
		my $ok     = delete $params{ok}     // 'OK';
		my $cancel = delete $params{cancel} // 'Cancel';
		my $input  = Term::Fabulous::Widget::TextField->new( %field, layout => { sizing => { width => sizing_grow() } } );
		$input->editor->select_all;    # typing replaces what the field starts with
		return $class->new(
			%params,
			fields  => [ { name => 'value', label => $label, input   => $input } ],
			buttons => [ { id   => 'ok',    label => $ok,    primary => 1 }, { id => CANCEL, label => $cancel } ],
		)->open($ui);
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Prompt - A dialog that asks a question and
waits for the answer

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Prompt;

	# A message with an OK button:
	Term::Fabulous::Widget::Prompt->alert( $ui, title => 'Saved', message => 'The notes are in [bold]notes.txt[/].' );

	# A question:
	Term::Fabulous::Widget::Prompt->confirm(
		$ui,
		title   => 'Quit?',
		message => 'Your notes have unsaved changes.',
		ok      => 'Quit',
		cancel  => 'Keep editing',
		focus   => 'cancel',
	)->on( Answer => sub ($event) {
		$ui->loop->stop if $event->button eq 'ok';
		return;
	} );

	# One value:
	Term::Fabulous::Widget::Prompt->ask(
		$ui,
		title     => 'Save as',
		label     => 'File',
		value     => 'notes.txt',
		required  => 1,
	)->on( Answer => sub ($event) {
		save_as( $event->value('value') ) if $event->button eq 'ok';
		return;
	} );

	# A form of your own:
	my $prompt = Term::Fabulous::Widget::Prompt->new(
		title   => 'New contact',
		fields  => [
			{ name => 'name',  label => 'Name',   input => Term::Fabulous::Widget::TextField->new( required  => 1 ) },
			{ name => 'email', label => 'E-mail', input => Term::Fabulous::Widget::TextField->new( validator => 'email' ) },
		],
		buttons => [ { id => 'add', label => 'Add', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
	);
	$prompt->on( Answer => sub ($event) { add_contact( $event->values ) if $event->button eq 'add'; return } );
	$prompt->open($ui);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-prompt.svg" alt="A New contact prompt over the dimmed list of contacts: Name holds Ada Lovelace, E-mail holds ada@engine in red, and the red line E-mail: Please enter an e-mail address. sits above the Add and Cancel buttons"></p>

=end html

The program is F<examples/widgets/prompt.pl>. The picture shows the
prompt after the user pressed Add with an e-mail address that is not
valid: the prompt stays open, says what is wrong, and puts the cursor
in the field.

=head1 DESCRIPTION

A prompt is a L<Term::Fabulous::Widget::Dialog> made for the questions
a program asks again and again: to confirm a step that cannot be
undone, to ask for a name, or to say that something happened. It has
a title, a message, optional input fields and a row of buttons, and it
reports the answer with one event, L<Answer|Term::Fabulous::Event::Answer>.

=head2 Prompts in one call

The class methods L</alert>, L</confirm> and L</ask> build the three
most common prompts, open them and return them, so a program only adds
its C<Answer> listener. Every other prompt is built with L</new> and
opened with L<open|Term::Fabulous::Widget::Dialog/open>, like any
dialog.

=head2 Answers

Every button has an id. When the user presses a button, the prompt
closes, the focus goes back to the widget that had it before, and the
prompt fires C<Answer> with the id of the button and the values of its
fields. C<Escape> closes the prompt as well. It then answers with the
button id C<cancel>, and the event's C<dismissed> is true. Name a
button C<cancel>, as the shortcuts do, and Escape and that button are
handled by the same code. A prompt answers once each time it is
opened.

=head2 Fields and their checks

A field is any input widget, with a name for its value and an optional
label in front of it. The prompt does not check values itself: it asks
the inputs, which check their values with their C<required> and
C<validator> parameters (see L<Term::Fabulous::Widget::Input/validator>).

A button marked as I<primary> checks the values before it answers. If an
input is not valid, the prompt stays open, shows the label of the field
and what is wrong with its value in the line above the buttons, and
moves the focus to that input. An input made of other widgets, such as a
L<Term::Fabulous::Widget::ColorPicker>, passes the focus to its first
invalid part that can take it (the picker's text field), or else to the
first focusable widget inside it. A C<check> of the whole prompt runs
after the inputs, for rules that involve more than one field. Buttons
that are not primary, such as Cancel, answer without checking.

=head2 Keys

Tab and Shift+Tab move between the fields and the buttons, as in every
dialog. C<Enter> on a button presses it. C<Enter> in a text field
presses the I<default button>, the first primary button (or the first
button when none is primary). C<Escape> dismisses the prompt.

When the prompt opens, the first field gets the focus, or the first
button when there are no fields. The C<focus> parameter names another
one; a field whose input cannot take the focus itself passes it to the
first focusable widget inside that input. A prompt that asks before
deleting something can start on its Cancel button, so that a hasty
C<Enter> does not delete anything.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $prompt = Term::Fabulous::Widget::Prompt->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Dialog/new>
(C<id>, C<layout>, C<backdrop_color>, C<close_on_escape>, ...) and the
ones below. All are optional, and unknown parameters die. A prompt is
laid out like a dialog, with two columns of padding at the sides
instead of one.

=over

=item C<title>

A character string, drawn in bold on the first row. Default: C<''>, no
title.

=item C<message>

The text below the title, in the rich markup of
L<Term::Fabulous::Text::Markup>, so C<[bold]notes.txt[/]> is bold.
Default: C<''>, no message. The message wraps at the width of the
prompt. A tag with a style that does not exist dies.

=item C<fields>

An array reference of fields, each a hash reference:

=over

=item C<name>

The name of the value, a string. Required. Two fields with the same
name die.

=item C<input>

The input widget: a L<Term::Fabulous::Widget::TextField>, a
L<Term::Fabulous::Widget::Dropdown>, a
L<Term::Fabulous::Widget::Checkbox>, or any other widget that has a
C<value> method. Required. Give a text field the width to grow into,
with C<< layout => { sizing => { width => sizing_grow() } } >>,
otherwise it is only as wide as its text.

=item C<label>

A string shown in front of the input. Optional. The labels of all
fields share a column as wide as the longest of them.

=back

Default: C<[]>, no fields. Unknown keys die.

=item C<buttons>

An array reference of buttons, each a hash reference with an C<id>
(a string, required, unique), a C<label> (a string, required) and
C<primary> (a boolean, default 0). Primary buttons get the class
C<primary>, which a theme may give a look of its own (see
L<Term::Fabulous::Manual::Looks/Variants and classes>), and check the
values before they answer. The buttons are drawn in the order given,
from the left. Default: one primary button C<ok> labelled C<OK>.

=item C<width>

The width of the prompt in columns, a positive integer. Default: 60. On
a screen narrower than that, the prompt is as wide as the screen, and
its message wraps to fit. A width in the C<sizing> of C<layout> wins
over it.

=item C<focus>

The name of a field or the id of a button, which gets the focus when
the prompt opens. Default: C<undef>, the first field or button. A name
that is no field and no button dies, and so does one that is both.

=item C<check>

A code reference that checks the values of the whole prompt, after the
inputs found nothing wrong. It is called with a hash reference of the
values by field name and returns what is wrong, as a sentence the
prompt shows, or a false value when everything is fine:

	check => sub ($values) {
		return 'The passwords differ.' if $values->{password} ne $values->{again};
		return;
	},

Default: C<undef>, no check.

=back

=head1 CLASS METHODS

Each of these builds a prompt, opens it in C<$ui> and returns it. The
parameters are those of L</new>, except C<buttons> (and C<fields> for
C<ask>), which these methods set themselves, plus the ones named below.

=head2 alert

	Term::Fabulous::Widget::Prompt->alert( $ui, title => 'Done', message => 'Copied 3 files.' );

A message with one primary button C<ok>. C<ok> is its label, C<OK> by
default.

=head2 confirm

	my $prompt = Term::Fabulous::Widget::Prompt->confirm( $ui, title => 'Delete 3 files?', ok => 'Delete', focus => 'cancel' );

A question with a primary button C<ok> and a button C<cancel>.
C<ok> and C<cancel> are their labels, C<OK> and C<Cancel> by default.

=head2 ask

	my $prompt = Term::Fabulous::Widget::Prompt->ask( $ui, title => 'Rename', label => 'Name', value => 'notes.txt', required => 1 );

A question with one text field named C<value>, and the buttons C<ok>
and C<cancel>. The field starts with the text of C<value>, all of it
selected, so typing replaces it. C<placeholder>, C<required> and
C<validator> are passed to the L<Term::Fabulous::Widget::TextField>,
C<label> is the label of the field, and C<ok> and C<cancel> are the
labels of the buttons. The answer's C<< $event->value('value') >> is
the text.

=head1 METHODS

A prompt has all methods of L<Term::Fabulous::Widget::Dialog>
(C<open>, C<close>, C<is_open>, ...) plus these.

=head2 answer

	$prompt->answer('ok');

Answers the prompt as the button with this id does when the user
presses it: a primary button checks the values first and keeps the
prompt open while something is wrong. Otherwise the prompt closes and
fires C<Answer>. Dies for an id the prompt has no button of, and when
the prompt is not open. Returns the prompt.

=head2 values

	my $values = $prompt->values;    # { name => 'Ada', email => '' }

The values of the fields as they are now, by field name, as a new hash
reference.

=head2 input

	my $field = $prompt->input('email');

The input widget of a field. Dies for a name the prompt has no field
of.

=head2 button

	$prompt->button('delete')->disabled(1);

The L<Term::Fabulous::Widget::Button> of a button. Dies for an id the
prompt has no button of.

=head2 field_names, button_ids

	my @names = $prompt->field_names;
	my @ids   = $prompt->button_ids;

The names of the fields and the ids of the buttons, in order.

=head2 default_button

	my $id = $prompt->default_button;

The id of the button that C<Enter> in a text field presses: the first
primary button, or the first button when none is primary.

=head2 error

	my $problem = $prompt->error;

What the line above the buttons says is wrong, or C<undef> while it
says nothing. Opening the prompt again empties it.

=head2 title, message

	$prompt->title('Delete 4 files?');
	$prompt->message('They go to the trash.');

Accessors for the parameters of the same names. Writing one changes the
open prompt with the next frame. An empty string takes the title or the
message away.

=head1 EVENTS

Besides the events of every dialog, a prompt fires:

=over

=item C<Answer> (L<Term::Fabulous::Event::Answer>)

The prompt was answered. Fired on the prompt after it closed and gave
the focus back, once per opening. The C<Close> event of the dialog
comes first.

=back

The C<Submit> of a text field inside the prompt presses the default
button. The C<Activate> events of the buttons and the C<Change> events
of the inputs bubble through the prompt as usual.

=head1 KDL PROPERTIES

A prompt is built in Perl only. Its fields are widgets and its answer
comes as an event, which a layout file cannot express. For a dialog
from a layout file, see L<Term::Fabulous::Widget::Dialog/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Event::Answer>, L<Term::Fabulous::Widget::Dialog>,
L<Term::Fabulous::Manual::Feedback/PROMPTS>,
L<Term::Fabulous::Cookbook::Forms/Confirm before quitting (Prompt)>,
L<Term::Fabulous::Cookbook::Forms/Ask for a number and check it (Prompt, validator)>,
L<Term::Fabulous::Manual::Forms> for checks of input values.

=cut
