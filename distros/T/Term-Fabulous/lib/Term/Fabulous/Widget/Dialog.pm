package Term::Fabulous::Widget::Dialog;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dialog::Backdrop;

our $VERSION = '0.05';

class Term::Fabulous::Widget::Dialog
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::XS qw(sizing_fit sizing_grow CLAY_TOP_TO_BOTTOM CLAY_ATTACH_TO_ROOT CLAY_ATTACH_POINT_RIGHT_CENTER);
	use List::Util qw(first min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(boolean describe integer one_of string);
	use Term::Fabulous::Event::Answer;
	use Term::Fabulous::Event::Close;
	use Term::Fabulous::Placement qw(TOPMOST_Z_INDEX);
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::Text;

	use constant DISMISSED      => 'cancel';    # the button a dismissed dialog answers with
	use constant RIGHT_EDGE     => -1;    # a dialog on the right keeps a column free at the edge
	use constant LOWEST_Z_INDEX => -32768;    # Clay's z_index is a 16-bit integer, up to TOPMOST_Z_INDEX

	my %DEFAULT_LAYOUT = (
		layout_direction => CLAY_TOP_TO_BOTTOM,
		padding          => { left => 1, right => 1, top => 1, bottom => 1 },
		child_gap        => 1,
	);

	field $z_index         :param = 1000;
	field $close_on_escape :param = 1;
	field $title           :param = '';
	field $notice_line     :param = 'shown';
	field $placement       :param = 'center';

	field @_buttons;    # { id, label, primary, widget }, in order
	field $_title_text;
	field $_notice_line;    # a box around the notice text, above the buttons
	field $_notice_text;
	field $_button_row;

	# The Term::Fabulous::Widget::Dialog::Backdrop while open. The tree owns
	# it (it holds the dialog as its child), so the reference is weak: a
	# dialog left open in a dropped UI is freed with it.
	field $_backdrop;
	field $_is_open = 0;

	# A dialog looks like a dialog unless told otherwise: a panel in the
	# theme's dialog colors and border (dialog.border.enabled), laid out
	# top to bottom with a cell of padding.
	sub BUILDARGS ( $class, %params ) {
		$params{layout} = { %DEFAULT_LAYOUT, %{ $params{layout} // {} } };
		return $class->SUPER::BUILDARGS(%params);
	}

	ADJUST :params ( :$buttons = [] ) {
		$z_index         = $self->_checked_z_index($z_index);
		$close_on_escape = boolean( $self, close_on_escape => $close_on_escape );
		$title           = string( $self, title => $title );
		$notice_line     = one_of( $self, notice_line => $notice_line, qw(shown kept row) );
		$placement       = one_of( $self, placement   => $placement,   qw(center right) );
		@_buttons        = $self->_parsed_buttons($buttons);

		$_title_text  = Term::Fabulous::Widget::Text->new( text   => $title, bold => 1 );
		$_notice_text = Term::Fabulous::Widget::Text->new( markup => '' );
		$_notice_line = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_fit( $notice_line eq 'row' ? 1 : 0 ) } } );
		$_notice_line->add_child($_notice_text);
		$_button_row = $self->_button_row if @_buttons;
		$self->add_child($_title_text) if length $title;
		$self->_float_on_the_right if $placement eq 'right';
	}

	method theme_family :common () {
		return 'dialog';
	}

	method themed_params :common () {
		return ( $class->SUPER::themed_params, backdrop_color => [ 'backdrop', 'normal', 'color' ] );
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			z_index         => 'scalar',
			close_on_escape => 'boolean',
			title           => 'scalar',
			notice_line     => 'scalar',
			placement       => 'scalar',
		);
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	method _parsed_buttons ($buttons) {
		die ref($self) . ": buttons must be an array reference, got " . describe($buttons) unless ref $buttons eq 'ARRAY';
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

	# A dialog on the right floats at the right edge of the screen, over
	# its backdrop.
	method _float_on_the_right () {
		$self->floating(
			{
				attach_to     => CLAY_ATTACH_TO_ROOT,
				attach_points => { element => CLAY_ATTACH_POINT_RIGHT_CENTER, parent => CLAY_ATTACH_POINT_RIGHT_CENTER },
				offset        => { x       => RIGHT_EDGE,                     y      => 0 },
				z_index       => min( $z_index + 1, TOPMOST_Z_INDEX ),
			}
		);
		return;
	}

	# ---------------------------------------------------------------------
	# The parts: title, buttons and the notice line
	# ---------------------------------------------------------------------

	method _button_row () {
		my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
		foreach my $button (@_buttons) {
			my $id     = $button->{id};
			my $widget = Term::Fabulous::Widget::Button->new( bordered => 1, classes => $button->{primary} ? ['primary'] : [], layout => { padding => { left => 1, right => 1 } } );
			$widget->add_child( Term::Fabulous::Widget::Text->new( text => $button->{label} ) );
			$widget->on( Activate => sub ( $self, $event ) { $self->press_button($id); return }, owner => $self );
			$button->{widget} = $widget;
			$row->add_child($widget);
		}
		return $row;
	}

	# The title first; the notice line, when it shows, and the buttons
	# last, unless a subclass put the buttons elsewhere.
	method place_parts () {
		$self->_show_title;
		$self->remove_child( grep { defined } $_notice_line, $_button_row );    # a row elsewhere stays there
		$self->add_child($_notice_line) if $self->_shows_notice_line;
		$self->add_child($_button_row) if defined $_button_row && !defined $_button_row->parent;
		return $self;
	}

	method _holds ($part) {
		my $parent = defined $part ? $part->parent : undef;
		return defined $parent && refaddr($parent) == refaddr($self) ? 1 : 0;
	}

	method _show_title () {
		return $self->remove_child($_title_text) unless length $title;
		$self->insert_children( 0, $_title_text ) unless $self->_holds($_title_text);
		return;
	}

	method _shows_notice_line () {
		return $notice_line ne 'shown' || length $_notice_text->text;
	}

	# The notice line comes and goes in its place, above the buttons.
	method _show_notice_line () {
		return $self->remove_child($_notice_line) unless $self->_shows_notice_line;
		return if $self->_holds($_notice_line);
		my $children = $self->children;
		my $row      = first { refaddr( $children->[$_] ) == refaddr( $_button_row // $self ) } 0 .. $#$children;
		$self->insert_children( $row // scalar @$children, $_notice_line );
		return;
	}

	method title (@new) {
		return $title unless @new;
		$title = string( $self, title => $new[0] );
		$_title_text->text($title);
		$self->_show_title;
		return $title;
	}

	# What the line above the buttons says, in rich markup: an error in
	# the color of an invalid input, anything else in the text color.
	method notice (@new) {
		return length $_notice_text->text ? $_notice_text->markup : undef unless @new;
		my ( $markup, $kind ) = @new;
		$markup = string( $self, notice => $markup );
		$kind   = one_of( $self, 'the kind of a notice' => $kind // 'info', qw(info error) );
		$_notice_text->markup($markup);
		$kind eq 'error' ? $_notice_text->text_color( $self->family_look( input => 'text', 'invalid' ) ) : $_notice_text->reset_look('text_color');
		$self->_show_notice_line;
		return $self;
	}

	method button ($id) {
		return $self->_button($id)->{widget};
	}

	method is_primary ($id) {
		return $self->_button($id)->{primary};
	}

	method _button ($id) {
		my $button = first { $_->{id} eq ( $id // '' ) } @_buttons;
		die ref($self) . ": the dialog has no button with the id " . describe($id) unless defined $button;
		return $button;
	}

	# The notice as it reads, without its markup.
	method notice_text () {
		my $text = $_notice_text->text;
		return length $text ? $text : undef;
	}

	method button_ids () {
		return map { $_->{id} } @_buttons;
	}

	method button_row () {
		return $_button_row;
	}

	# The button Enter in a field presses where a dialog wants it to: the
	# first primary one, or the first one.
	method default_button () {
		return undef unless @_buttons;
		my $primary = first { $_->{primary} } @_buttons;
		return ( $primary // $_buttons[0] )->{id};
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	# The backdrop reads the color when a frame is drawn.
	method backdrop_color (@new) {
		return $self->look_value('backdrop_color') unless @new;
		return $self->set_look( backdrop_color => $new[0] );
	}

	method _checked_z_index ($value) {
		$value = integer( $self, z_index => $value );
		die ref($self) . ": z_index must be an integer from " . LOWEST_Z_INDEX . " to " . TOPMOST_Z_INDEX . ", got $value" if $value < LOWEST_Z_INDEX || $value > TOPMOST_Z_INDEX;
		return $value;
	}

	method z_index (@new) {
		return $z_index unless @new;
		$z_index = $self->_checked_z_index( $new[0] );
		$_backdrop->floating( { %{ $_backdrop->floating }, z_index => $z_index } ) if defined $_backdrop;
		$self->_float_on_the_right if $placement eq 'right';
		return $z_index;
	}

	method close_on_escape (@new) {
		return $close_on_escape unless @new;
		return $close_on_escape = boolean( $self, close_on_escape => $new[0] );
	}

	method notice_line (@new) {
		return $notice_line unless @new;
		$notice_line = one_of( $self, notice_line => $new[0], qw(shown kept row) );
		$_notice_line->layout( { %{ $_notice_line->layout }, sizing => { width => sizing_grow(), height => sizing_fit( $notice_line eq 'row' ? 1 : 0 ) } } );
		$self->_show_notice_line;
		return $notice_line;
	}

	# A dialog in the center sits in its backdrop's layout; one on the
	# right floats.
	method placement (@new) {
		return $placement unless @new;
		$placement = one_of( $self, placement => $new[0], qw(center right) );
		$placement eq 'right' ? $self->_float_on_the_right : $self->floating(undef);
		return $placement;
	}

	method is_open () {
		return $_is_open;
	}

	method backdrop () {
		return $_backdrop;
	}

	# What an answer carries besides what answer is given: nothing for a
	# plain dialog; a subclass with fields reports them.
	method values () {
		return {};
	}

	# ---------------------------------------------------------------------
	# Opening, answering and closing
	# ---------------------------------------------------------------------

	method open ($ui) {
		die "Term::Fabulous::Widget::Dialog: open needs the Term::Fabulous object, got " . ( ref $ui || $ui // 'undef' )
			unless blessed $ui && $ui->isa('Clay::UI');
		return $self if defined $_backdrop;
		die "Term::Fabulous::Widget::Dialog: a dialog that is a child of another widget cannot open" if defined $self->parent;

		$self->place_parts;
		my $interaction = $ui->interaction;
		my $backdrop    = Term::Fabulous::Widget::Dialog::Backdrop->new(
			dialog       => $self,
			z_index      => $z_index,
			focus_before => $interaction->get_focused_widget,
		);
		$backdrop->add_child($self);
		$ui->root->add_child($backdrop);
		weaken( $_backdrop = $backdrop );
		$_is_open = 1;
		$interaction->set_focused_widget( $backdrop->get_next_focus );
		return $self;
	}

	# What pressing a button does: the dialog answers with its id. A
	# subclass whose buttons do more overrides it.
	method press_button ($id) {
		return $self->answer($id);
	}

	method answer ( $id, %values ) {
		$id = string( $self, 'the id of an answer' => $id );
		$self->_button($id) if @_buttons;
		die ref($self) . ": answer needs an open dialog" unless $_is_open;
		return $self->_finish( $id, { %{ $self->values }, %values }, 0 );
	}

	# Escape, or close from the program: the dialog is dismissed and
	# answers cancel with its values.
	method close () {
		return $self unless $_is_open;
		return $self->_finish( DISMISSED, $self->values, 1 );
	}

	# Removing the backdrop gives the focus back: the backdrop names the
	# widget that had it as its focus heir. The program may have taken the
	# backdrop out of the tree already (with clear_children on the root,
	# for example): then there is nothing to remove, but Close and Answer
	# still fire.
	method _finish ( $button, $values, $dismissed ) {
		my $backdrop = $_backdrop;
		( $_is_open, $_backdrop ) = ( 0, undef );
		if ( defined $backdrop ) {
			my $holder = $backdrop->parent;
			$holder->remove_child($backdrop) if defined $holder;
			$backdrop->clear_children;
		}
		$self->fire_event( Term::Fabulous::Event::Close->new );
		$self->fire_event( Term::Fabulous::Event::Answer->new( button => $button, values => $values, dismissed => $dismissed ) );
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Dialog - A box that opens over the whole screen,
keeps the focus and answers

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Dialog;
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::Text;
	use Clay::XS qw(sizing_fixed);

	my $dialog = Term::Fabulous::Widget::Dialog->new(
		id     => 'confirm',
		layout => { sizing => { width => sizing_fixed(40) } },
	);
	my $quit = Term::Fabulous::Widget::Button->new( background_color => [ 40, 60, 90, 255 ], layout => { padding => { left => 1, right => 1 } } );
	$quit->add_child( Term::Fabulous::Widget::Text->new( text => 'Quit', text_color => [ 255, 255, 255, 255 ] ) );
	$dialog->add_child(
		Term::Fabulous::Widget::Text->new( text => 'Really quit? Escape cancels.', text_color => [ 220, 220, 220, 255 ] ),
		$quit,
	);
	$quit->on( Activate => sub ($event) { $ui->loop->stop; return } );
	$dialog->on( Close => sub ($event) { $status->text('cancelled'); return } );

	# From a key binding or a button:
	$dialog->open($ui);

	# A dialog with its own title, buttons and notice line:
	my $export = Term::Fabulous::Widget::Dialog->new(
		title   => 'Export the table',
		buttons => [ { id => 'export', label => 'Export', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
	);
	$export->add_child( Term::Fabulous::Widget::Text->new( text => 'All 120 rows go to export.csv.' ) );
	$export->on( Answer => sub ($event) {
		export_csv() if $event->button eq 'export';    # Escape answers cancel, dismissed
		return;
	} );
	$export->open($ui);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-dialog.svg" alt="A Delete 3 files? dialog with Delete and Cancel buttons over a dimmed list of files; Delete has the focus and a blue border"></p>

=end html

The program is F<examples/widgets/dialog.pl>.

=head1 DESCRIPTION

A Dialog is a L<Term::Fabulous::Widget::Box> that is not part of the
layout until it is opened. L</open> puts it in the center of the
screen (or at its right edge, see C<placement>), on top of everything else, behind a translucent backdrop that
dims the rest of the screen, and gives the keyboard focus to the first
widget inside it. While it is open:

=over

=item *

Tab and Shift+Tab cycle through the widgets inside the dialog only;

=item *

mouse clicks outside the dialog reach nothing behind it, whatever the
C<backdrop_color>: they move the focus onto the backdrop, from where
Tab goes to the first widget of the dialog and Shift+Tab to the last,
and their C<Mouse> events are fired on the backdrop, from where they
bubble to the root widget (the backdrop's parent), not to the widgets
behind the dialog;

=item *

key presses go to the focused widget inside the dialog and bubble up
through the dialog to the backdrop, where C<Escape> closes the dialog
(unless C<close_on_escape> is off). They go no further: the widgets
and key bindings behind the dialog do not see them. Ctrl+C still ends
the program (unless the UI was made with C<< stop_on_ctrl_c =E<gt> 0 >>),
Tab and Shift+Tab still move the focus;

=item *

the focus stays inside the dialog: when the focused widget is disabled
or removed, its nearest ancestor that can take the focus does, which
is the backdrop unless a widget inside the dialog is closer, and when
the program focuses nothing the backdrop takes it (an C<OnBlur>
listener inside the dialog must let the event bubble for that, see
L<Term::Fabulous::Widget::Dialog::Backdrop>);

=item *

the widgets behind the dialog stay visible through the backdrop, but
are neither hovered nor pressed.

=back

L</close> takes the dialog off the screen, puts the focus back on the
widget that had it before (if that widget can still take the focus), and
fires C<Close> (L<Term::Fabulous::Event::Close>) and then C<Answer>
(L</Answers>) on the dialog. A closed dialog can be opened again, as
often as needed, and keeps its children and their state in between.

=head2 Title, buttons and the notice line

A dialog can bring the parts most dialogs have. A C<title> is a bold
line at the top. C<buttons> are one row of bordered buttons at the
bottom; pressing one makes the dialog L</answer> with the button's id.
The I<notice line> above the buttons says something with L</notice>,
for example what is wrong with an input. The children the program adds
go between the title and the notice line: the dialog puts its parts in
their places when it opens (see L</place_parts>).

=head2 Answers

Every time a dialog closes, it fires two events on itself: C<Close>,
then L<Answer|Term::Fabulous::Event::Answer>. An answer through
L</answer> (a button, or the program) names its button and carries the
dialog's L</values> and the values given. A dialog closed without an
answer (C<Escape>, or L</close> from the program) is I<dismissed>: it
answers with the button C<cancel> and the dialog's L</values>, and the
event's C<dismissed> is true. That is one rule for every dialog:
L<Term::Fabulous::Widget::Prompt> reports its fields as its values, and
L<Term::Fabulous::Widget::FileDialog> (its choice answers with the
path), L<Term::Fabulous::Widget::KeyReference> (its Close button answers
C<close>) and a plain dialog have none. When the listeners run, the
dialog is closed and the focus is back where it was.

A Dialog comes with a look from the theme's C<dialog> family (a dark
background and a round border in the accent blue in the built-in dark
theme), one cell of padding and a vertical layout with a gap of one
row between the children. Every one of these is an ordinary Box
parameter and can be overridden. Give the dialog a
width (C<sizing> in C<layout>); without one it is as wide as its
widest child.

=head1 CONSTRUCTOR

=head2 new

	my $dialog = Term::Fabulous::Widget::Dialog->new(%parameters);

All parameters are optional; unknown parameters die. A Dialog takes
every parameter of L<Term::Fabulous::Widget::Box> (see
L<Term::Fabulous::Widget/new>), with the defaults described above,
plus:

=over

=item C<backdrop_color>

The color of the layer behind the dialog, in any format
L<Term::Fabulous::Color> accepts. Default: the theme's
C<dialog.backdrop>, C<[ 0, 0, 0, 128 ]> in the dark theme, black at
half opacity, which dims the screen behind the dialog. An opaque color
hides it; alpha 0 leaves it as it is.

=item C<z_index>

An integer from -32768 to 32767; other values die. Dialogs and other floating widgets with a higher value are
drawn over those with a lower one. Default: 1000. Popups (the open list
of a L<Term::Fabulous::Widget::Dropdown>, a popup
L<Term::Fabulous::Widget::Menu>, a table's column chooser) float at
L<Term::Fabulous::Placement/TOPMOST_Z_INDEX>, so they are drawn over the
dialog they are in.

=item C<close_on_escape>

A boolean. Default: 1: C<Escape>, pressed while the focus is inside the
dialog, closes it. With 0 the program closes the dialog itself.

=item C<title>

A character string, drawn in bold on the first row. Default: C<''>, no
title.

=item C<buttons>

An array reference of buttons, each a hash reference with an C<id> (a
string, required, unique), a C<label> (a string, required) and
C<primary> (a boolean, default 0). They are drawn in one row at the
bottom, in the order given, from the left, each bordered with a column
of padding on either side; primary buttons get the class C<primary>,
which a theme may give a look of its own (see
L<Term::Fabulous::Manual::Looks/Variants and classes>). Pressing one
calls L</press_button>, which answers with its id. Unknown keys die.
Default: C<[]>, no buttons.

=item C<notice_line>

When the notice line above the buttons takes room: C<shown> (the
default), only while it says something; C<kept>, always in its place,
without rows while it says nothing (the gap above it stays); C<row>,
always at least one row high, so that a notice does not change the
height of the dialog. Anything else dies.

=item C<placement>

C<center> (the default): the dialog sits in the middle of the screen.
C<right>: it floats at the right edge of the screen, a column from it,
centered from top to bottom, just above its backdrop's C<z_index>.
Anything else dies.

=back

=head1 METHODS

A Dialog has all methods of L<Term::Fabulous::Widget> plus these:

=head2 open

	$dialog->open($ui);

Opens the dialog in the L<Term::Fabulous> object C<$ui>: adds it to
the screen as described above and focuses the first focusable widget
inside it (the backdrop when there is none). Opening an open dialog
does nothing. Dies when C<$ui> is not a L<Term::Fabulous> (or other
L<Clay::UI>) object, and when the dialog has been added to another
widget as a child. Returns the dialog.

=head2 close

	$dialog->close;

Dismisses the dialog: removes it from the screen, gives the focus back
to the widget that had it when the dialog opened (if that widget still
exists and can take the focus; the backdrop names it as its focus heir,
see L<Term::Fabulous::Widget::Dialog::Backdrop/focus_heir>) and fires
C<Close> and C<Answer> (C<cancel>, dismissed) on the dialog. Closing a
closed dialog does nothing. A dialog
whose backdrop the program took out of the tree itself (with
C<clear_children> on the root, for example) is still open until
C<close> is called; the focus went back when the backdrop left, and
C<close> then only fires C<Close> and C<Answer>. Returns the dialog.

=head2 answer

	$dialog->answer('export');
	$dialog->answer( save => path => $path );

Closes the dialog and fires C<Close> and then C<Answer> with this
button id, the dialog's L</values> and the values given (which win
over them), not dismissed (see L</Answers>). A dialog with buttons dies
for an id that is none of them; one without buttons answers with any
string. Dies when the dialog is not open. Returns the dialog.

=head2 press_button

	$dialog->press_button('export');

What pressing a button does. In a Dialog, it answers with the button's
id. A subclass whose buttons do more first (check the inputs, choose a
file) overrides it. Returns the dialog.

=head2 values

	my $values = $dialog->values;

What every answer of the dialog carries, as a new hash reference: an
empty hash in a Dialog. A subclass with inputs reports them (see
L<Term::Fabulous::Widget::Prompt/values>).

=head2 notice

	$dialog->notice( 'The name is taken.', 'error' );
	$dialog->notice('Saved [bold]notes.txt[/].');
	$dialog->notice('');    # says nothing
	my $markup = $dialog->notice;

Says something in the notice line above the buttons, in the rich markup
of L<Term::Fabulous::Text::Markup> (escape text of the user with
L<escape_markup|Term::Fabulous::Text::Markup/escape_markup>). The kind
is C<info> (the default, the text color) or C<error> (the color of an
invalid input, the theme's C<input.text.invalid>); anything else dies.
An empty markup says nothing. The line wraps at the width of the
dialog; when it takes room depends on C<notice_line>. Returns the
dialog. Without arguments, returns the markup shown, or C<undef> while
the line says nothing.

=head2 notice_text

	my $text = $dialog->notice_text;

What the notice line says, as plain text without the markup, or
C<undef> while it says nothing.

=head2 title

	$dialog->title('Export 3 tables');

Accessor for the C<title>. Writing it changes the title line at once;
an empty string takes it away.

=head2 button, button_ids, is_primary, default_button

	$dialog->button('export')->disabled(1);
	my @ids     = $dialog->button_ids;
	my $checks  = $dialog->is_primary('export');
	my $default = $dialog->default_button;

The L<Term::Fabulous::Widget::Button> of a button (dying for an id the
dialog has no button of), the ids of the buttons in order, whether a
button is primary (1 or 0), and the button that a subclass presses for
C<Enter> in a field: the first primary button, the first button when
none is, or C<undef> without buttons.

=head2 notice_line, placement

	$dialog->placement('right');

Accessors for the parameters of the same names.

=head2 is_open

	if ( $dialog->is_open ) { ... }

1 while the dialog is open, 0 otherwise.

=head2 backdrop

	my $backdrop = $dialog->backdrop;

The L<Term::Fabulous::Widget::Dialog::Backdrop> behind the open dialog,
or C<undef> while it is closed or after the program took it out of the
tree. Rarely needed.

=head2 backdrop_color, z_index, close_on_escape

	$dialog->backdrop_color( [ 0, 0, 0, 200 ] );
	$dialog->z_index(2000);
	$dialog->close_on_escape(0);

Accessors for the constructor parameters of the same names. Without an
argument they return the current value; with one they set it and return
the stored form. Changes to C<backdrop_color> and C<z_index> show on an
open dialog with the next frame.

=head1 SUBCLASS INTERFACE

=head2 place_parts

	$self->place_parts;

Puts the parts of the dialog in their places: the title first, the
notice line (when C<notice_line> says it takes room) and the button row
last. L</open> calls it, so children added before then end up between
them. A subclass that rebuilds its children while the dialog is open
calls it afterwards. A button row the subclass put inside one of its
own boxes stays there. Returns the dialog.

=head2 button_row

	$search_row->add_child( $search, $self->button_row );

The box with the buttons, or C<undef> without buttons. A subclass may
put it somewhere else in the dialog (L<Term::Fabulous::Widget::KeyReference>
puts it next to its search field on a short screen).

=head1 EVENTS

Besides the events of every Box (L<Term::Fabulous::Widget::Box/EVENTS>),
a Dialog fires:

=over

=item C<Close> (L<Term::Fabulous::Event::Close>)

The dialog was closed: by an answer, by C<Escape> or by L</close>.
Fired on the dialog after it has left the screen, so it does not bubble
anywhere.

=item C<Answer> (L<Term::Fabulous::Event::Answer>)

Right after C<Close>, every time: the button that answered and the
values, or C<cancel> as dismissed (see L</Answers>).

=back

Events from the widgets inside the dialog (C<Activate> of a Button,
C<Submit> of a text field, C<Change>, ...) bubble through the dialog as
usual, so one listener on the dialog can handle them all. The
C<Activate> of the dialog's own C<buttons> stops at the button, which
calls L</press_button>.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<backdrop_color> (a color string), C<z_index> (an integer from -32768
to 32767),
C<close_on_escape> (C<#true> or C<#false>), C<title>, C<notice_line>
and C<placement> (strings). C<buttons> is not a KDL property: a
dialog from a layout file has no buttons of its own; give it Button
children or build it in Perl.

A Dialog is added to the widget tree only when it opens, and a Dialog
that is a child of another widget cannot open. A layout file has only
one top-level widget, so a Dialog must be the root widget of a layout
file of its own. C<build> returns the dialog, which is not open yet.
With this in F<about.kdl>:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Dialog as Dialog
	use Term::Fabulous::Widget::Text as Text

	Dialog "about" {
		sizing width="fixed(40)"
		backdrop_color "rgba(0, 0, 0, 0.7)"
		Text { text "Term::Fabulous"; text_color "#ffffff"; }
	}

open the dialog from Perl:

=for highlighter language=perl

	my $about = Term::Fabulous::Layout->new( file => 'about.kdl' )->build;
	$about->open($ui);

=head1 SEE ALSO

L<Term::Fabulous::Widget::Box>, L<Term::Fabulous::Event::Close>,
L<Term::Fabulous::Event::Answer>,
L<Term::Fabulous::Widget::Dialog::Backdrop>,
L<Term::Fabulous::Widget::Prompt>, L<Term::Fabulous::Widget::FileDialog>,
L<Term::Fabulous::Widget::KeyReference>,
L<Term::Fabulous::Manual::Events/FOCUS>, L<Term::Fabulous::Widget/floating>,
L<Term::Fabulous::Manual::CustomWidgets/A dialog of your own>,
L<Term::Fabulous::Cookbook::Forms/Ask a question in a dialog (Dialog widget)>,
L<Term::Fabulous::Cookbook::Forms/A login form (centered dialog, masked password)>,
L<Term::Fabulous::Cookbook::Forms/Confirm before quitting (Prompt)>,
L<Term::Fabulous::Cookbook::Forms/Open and save a file (FileDialog)>,
L<Term::Fabulous::Cookbook::Menus/Show the keys in a help screen (KeyReference)>.

=cut
