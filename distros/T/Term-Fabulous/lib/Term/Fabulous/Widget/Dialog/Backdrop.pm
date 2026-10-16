package Term::Fabulous::Widget::Dialog::Backdrop;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::HasFocusOrder;
use Term::Fabulous::Widget::Box;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Dialog::Backdrop
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(
		CLAY_ATTACH_TO_ROOT CLAY_ATTACH_POINT_CENTER_CENTER
		CLAY_ALIGN_X_CENTER CLAY_ALIGN_Y_CENTER sizing_grow
	);
	use Scalar::Util qw(weaken);

	field $dialog :param :weak :reader;
	field $z_index :param;

	ADJUST {
		$self->floating(
			{
				attach_to     => CLAY_ATTACH_TO_ROOT,
				attach_points => { element => CLAY_ATTACH_POINT_CENTER_CENTER, parent => CLAY_ATTACH_POINT_CENTER_CENTER },
				z_index       => $z_index,
			}
		);
		$self->layout(
			{
				sizing          => { width => sizing_grow(),       height => sizing_grow() },
				child_alignment => { x     => CLAY_ALIGN_X_CENTER, y      => CLAY_ALIGN_Y_CENTER },
			}
		);
		$self->glyphs_show_through(1);

		weaken( my $weak_self = $self );
		$self->on( KeyPress => sub ($event) { return $weak_self->_handle_key($event) } );
		$self->on(
			OnBlur => sub ($event) {
				$weak_self->_keep_focus if defined $weak_self;
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
	}

	# The backdrop is painted in the dialog's backdrop color, read when
	# the frame is drawn, so a theme switch shows at once.
	method background_color :override (@new) {
		return $self->SUPER::background_color(@new) if @new;
		return $self->SUPER::background_color // ( defined $dialog ? $dialog->backdrop_color : undef );
	}

	method contribute_look_theme :override ($config) {
		my $background = $self->background_color // return;
		$config->{background_color} = $background;
		return;
	}

	# Every key stops here while the dialog is open: the widgets and key
	# bindings behind it do not see it. Escape closes the dialog.
	method _handle_key ($event) {
		my $owner = $dialog;
		return Clay::UI::Enum::Result->CONTINUE unless defined $owner && $owner->is_open;
		$owner->close if ( $event->main_key_name // '' ) eq 'Escape'  && $owner->close_on_escape;
		return Clay::UI::Enum::Result->HANDLED;
	}

	# The focus does not leave an open dialog for nothing: when the focused
	# widget inside it is disabled or removed, the backdrop takes it, so
	# keys and Tab stay inside the dialog.
	method _keep_focus () {
		return unless defined $dialog && $dialog->is_open;
		my $ui          = $self->ui // return;
		my $interaction = $ui->interaction;

		# A backdrop that is being removed (its OnBlur fires while it
		# leaves) cannot take the focus.
		return if defined $interaction->get_focused_widget || !$interaction->can_take_focus($self);
		$interaction->set_focused_widget($self);
		return;
	}

	# Tab and Shift-Tab step through the focusable widgets inside the
	# dialog, wrapping around; the backdrop itself takes the focus when
	# there are none, so the focus has somewhere to stay.
	method get_next_focus () {
		return $self unless defined $dialog;
		return $self->default_next_focus( within => $dialog ) // $self;
	}

	method get_previous_focus () {
		return $self unless defined $dialog;
		return $self->default_previous_focus( within => $dialog ) // $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Dialog::Backdrop - The screen-filling layer
behind an open dialog

=head1 DESCRIPTION

This class is internal to L<Term::Fabulous::Widget::Dialog>. When a
dialog opens, it creates one Backdrop, puts itself inside it and adds
the Backdrop to the root widget. The Backdrop

=over

=item *

floats over the whole screen (attached to the root, grown to its size,
with the dialog's C<z_index>), painted in the dialog's
C<backdrop_color> with the glyphs below showing through, and centers
the dialog in itself;

=item *

catches every mouse event outside the dialog, whatever its color,
since it covers every cell of the screen: the C<Mouse> and C<MouseMove>
events are fired on the Backdrop and bubble to the root widget, its
parent, not to the widgets behind it. Clay treats it as a floating
element that captures the pointer, so nothing below it is hovered or
pressed;

=item *

can take the keyboard focus, so a click outside the dialog focuses the
Backdrop instead of a widget behind it;

=item *

decides the Tab order while the focus is inside the dialog
(L<Clay::UI::Role::Interaction::HasFocusOrder>): Tab and Shift+Tab
cycle through the focusable widgets inside the dialog, and through the
Backdrop alone when there are none;

=item *

stops every key that the widgets inside the dialog let bubble, so the
widgets and key bindings behind the dialog see none; it closes the
dialog on C<Escape>, when the dialog's C<close_on_escape> is set;

=item *

takes the focus itself when the focused widget inside the dialog loses
it without another widget getting it (it is disabled or removed, or
the program focuses nothing), so keys and Tab stay inside the dialog.
It learns about that from the C<OnBlur> event bubbling up from the
widget, so an C<OnBlur> listener inside the dialog must let it bubble
(return C<Clay::UI::Enum::Result-E<gt>CONTINUE>).

=back

=head1 METHODS

=head2 dialog

The L<Term::Fabulous::Widget::Dialog> this Backdrop belongs to.

=head2 get_next_focus, get_previous_focus

The L<Clay::UI::Role::Interaction::HasFocusOrder> methods: the widget
after or before the focused one among the widgets inside the dialog
that can take the focus now, in tree order (also those a widget keeps
below an internal child, such as the items of a
L<Term::Fabulous::Widget::VirtualList>), wrapping around. They are the
tracker's default order limited to the dialog
(C<< default_next_focus( within => $dialog ) >>, see
L<Clay::UI::Interaction/default_next_focus>). From the Backdrop itself,
Tab goes to the first widget and Shift+Tab to the last; with no
focusable widget inside, both return the Backdrop.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Dialog>.

=cut
