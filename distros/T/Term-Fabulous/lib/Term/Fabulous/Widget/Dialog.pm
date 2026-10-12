package Term::Fabulous::Widget::Dialog;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dialog::Backdrop;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Dialog
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::XS qw(CLAY_TOP_TO_BOTTOM);
	use Scalar::Util qw(blessed weaken);
	use Term::Fabulous::Check qw(boolean integer);
	use Term::Fabulous::Event::Close;

	my %DEFAULT_LAYOUT = (
		layout_direction => CLAY_TOP_TO_BOTTOM,
		padding          => { left => 1, right => 1, top => 1, bottom => 1 },
		child_gap        => 1,
	);

	field $z_index         :param = 1000;
	field $close_on_escape :param = 1;

	# The Term::Fabulous::Widget::Dialog::Backdrop while open. The tree owns
	# it (it holds the dialog as its child), so the reference is weak: a
	# dialog left open in a dropped UI is freed with it.
	field $_backdrop;
	field $_is_open = 0;
	field $_focus_before;    # the widget focused when the dialog opened

	# A dialog looks like a dialog unless told otherwise: a panel in the
	# theme's dialog colors and border (dialog.border.enabled), laid out
	# top to bottom with a cell of padding.
	sub BUILDARGS ( $class, %params ) {
		$params{layout} = { %DEFAULT_LAYOUT, %{ $params{layout} // {} } };
		return $class->SUPER::BUILDARGS(%params);
	}

	ADJUST {
		$z_index         = integer( $self, z_index => $z_index );
		$close_on_escape = boolean( $self, close_on_escape => $close_on_escape );
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
		);
	}

	# The backdrop reads the color when a frame is drawn.
	method backdrop_color (@new) {
		return $self->look_value('backdrop_color') unless @new;
		return $self->set_look( backdrop_color => $new[0] );
	}

	method z_index (@new) {
		return $z_index unless @new;
		$z_index = integer( $self, z_index => $new[0] );
		$_backdrop->floating( { %{ $_backdrop->floating }, z_index => $z_index } ) if defined $_backdrop;
		return $z_index;
	}

	method close_on_escape (@new) {
		return $close_on_escape unless @new;
		return $close_on_escape = boolean( $self, close_on_escape => $new[0] );
	}

	method is_open () {
		return $_is_open;
	}

	method backdrop () {
		return $_backdrop;
	}

	method open ($ui) {
		die "Term::Fabulous::Widget::Dialog: open needs the Term::Fabulous object, got " . ( ref $ui || $ui // 'undef' )
			unless blessed $ui && $ui->isa('Clay::UI');
		return $self if defined $_backdrop;
		die "Term::Fabulous::Widget::Dialog: a dialog that is a child of another widget cannot open" if defined $self->parent;

		my $interaction = $ui->interaction;
		$_focus_before = $interaction->get_focused_widget;
		weaken $_focus_before if defined $_focus_before;

		my $backdrop = Term::Fabulous::Widget::Dialog::Backdrop->new( dialog => $self, z_index => $z_index );
		$backdrop->add_child($self);
		$ui->root->add_child($backdrop);
		weaken( $_backdrop = $backdrop );
		$_is_open = 1;
		$interaction->set_focused_widget( $backdrop->get_next_focus );
		return $self;
	}

	# The program may have taken the backdrop out of the tree already (with
	# clear_children on the root, for example): then there is nothing to
	# remove and no UI to give the focus back in, but Close still fires.
	method close () {
		return $self unless $_is_open;
		my $backdrop = $_backdrop;
		my $ui       = $self->ui;
		( $_is_open, $_backdrop ) = ( 0, undef );

		if ( defined $backdrop ) {
			my $holder = $backdrop->parent;
			$holder->remove_child($backdrop) if defined $holder;
			$backdrop->clear_children;
		}
		$self->_restore_focus($ui) if defined $ui;
		$self->fire_event( Term::Fabulous::Event::Close->new );
		return $self;
	}

	# The focus goes back to the widget that had it, if it still can take it.
	method _restore_focus ($ui) {
		my $previous = $_focus_before;
		$_focus_before = undef;
		return unless defined $previous && $ui->interaction->can_take_focus($previous);
		$ui->interaction->set_focused_widget($previous);
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Dialog - A box that opens over the whole screen
and keeps the focus

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

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-dialog.svg" alt="A Delete 3 files? dialog with Delete and Cancel buttons over a dimmed list of files; Delete has the focus and a blue border"></p>

=end html

The program is F<examples/widgets/dialog.pl>.

=head1 DESCRIPTION

A Dialog is a L<Term::Fabulous::Widget::Box> that is not part of the
layout until it is opened. L</open> puts it in the center of the
screen, on top of everything else, behind a translucent backdrop that
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
or removed, the backdrop takes the focus (an C<OnBlur> listener inside
the dialog must let the event bubble for that, see
L<Term::Fabulous::Widget::Dialog::Backdrop>);

=item *

the widgets behind the dialog stay visible through the backdrop, but
are neither hovered nor pressed.

=back

L</close> takes the dialog off the screen, puts the focus back on the
widget that had it before (if that widget can still take the focus),
and fires C<Close>
(L<Term::Fabulous::Event::Close>) on the dialog. A closed dialog can be
opened again, as often as needed, and keeps its children and their
state in between.

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
drawn over those with a lower one. Default: 1000. The open list of a
L<Term::Fabulous::Widget::Dropdown> floats over every z_index, so it is
drawn over the dialog it is in.

=item C<close_on_escape>

A boolean. Default: 1: C<Escape>, pressed while the focus is inside the
dialog, closes it. With 0 the program closes the dialog itself.

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

Closes the dialog: removes it from the screen, gives the focus back to
the widget that had it when the dialog opened (if that widget still
exists and can take the focus) and fires C<Close> on the dialog.
Closing a closed dialog does nothing. A dialog whose backdrop the
program took out of the tree itself (with C<clear_children> on the
root, for example) is still open until C<close> is called; C<close>
then only fires C<Close>. Returns the dialog.

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

=head1 EVENTS

Besides the events of every Box (L<Term::Fabulous::Widget::Box/EVENTS>),
a Dialog fires:

=over

=item C<Close> (L<Term::Fabulous::Event::Close>)

The dialog was closed, by C<Escape> or by L</close>. Fired on the
dialog after it has left the screen, so it does not bubble anywhere.

=back

Events from the widgets inside the dialog (C<Activate> of a Button,
C<Submit> of a text field, C<Change>, ...) bubble through the dialog as
usual, so one listener on the dialog can handle them all.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<backdrop_color> (a color string), C<z_index> (an integer from -32768
to 32767) and
C<close_on_escape> (C<#true> or C<#false>).

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
L<Term::Fabulous::Widget::Dialog::Backdrop>,
L<Term::Fabulous::Manual::Events/FOCUS>, L<Term::Fabulous::Widget/floating>,
L<Term::Fabulous::Cookbook::Forms/Ask a question in a dialog (Dialog widget)>,
L<Term::Fabulous::Cookbook::Forms/A login form (centered dialog, masked password)>.

=cut
