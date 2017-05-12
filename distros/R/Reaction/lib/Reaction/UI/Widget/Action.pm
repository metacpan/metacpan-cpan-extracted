package Reaction::UI::Widget::Action;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Object::Mutable';

after fragment widget {
  my $vp = $_{viewport};
  arg 'method' => $vp->method;
  arg 'form_id' => $vp->location;
  arg 'action' => $vp->has_action ? $vp->action : '';
};

implements fragment message {
  return unless $_{viewport}->has_message;
  arg message_string => $_{viewport}->message;
  render 'message_layout';
};

implements fragment error_message {
  return unless $_{viewport}->has_error_message;
  arg message_string => $_{viewport}->error_message;
  render 'error_message_layout';
};

implements fragment ok_button_fragment {
  if (grep { $_ eq 'ok' } $_{viewport}->accept_events) {
    arg 'event_id' => event_id 'ok';
    arg 'label' => localized $_{viewport}->ok_label;
    render 'ok_button';
  }
};

implements fragment apply_button_fragment {
  if (grep { $_ eq 'apply' } $_{viewport}->accept_events) {
    arg 'event_id' => event_id 'apply';
    arg 'label' => localized $_{viewport}->apply_label;
    render 'apply_button';
  }
};

implements fragment cancel_button_fragment {
  if (grep { $_ eq 'close' } $_{viewport}->accept_events) {
    arg 'event_id' => event_id 'close';
    arg 'label' => localized $_{viewport}->close_label;
    render 'cancel_button';
  }
};

implements fragment maybe_inner {
  if( my $inner = $_{viewport}->inner ){
    arg '_' => $inner;
    render 'viewport';
  }
};


__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Action

=head1 DESCRIPTION

This is a subclass of L<Reaction::UI::Widget::Object::Mutable>.

=head1 FRAGMENTS

=head2 widget

Additionally provides the C<method> argument containing the value of
the viewport's C<method>.

=head2 message

Empty if the viewport's C<has_message> returns false. Otherwise sets
the C<message_string> argument to the viewport's C<message> and
renders the C<message_layout> fragment.

=head2 error_message

Same as the C<message> fragment above except that it checks 
C<has_error_message>, sets C<message_string> to the viewport's
C<error_message> and renders C<error_message_layout>.

=head2 ok_button_fragment

Renders nothing unless the viewport accepts the C<ok> event.

If it does, it provides the following arguments before rendering C<ok_button>:

=over 4

=item event_id

Is set to the event id C<ok>.

=item label

Is set to the localized C<ok_label> of the viewport.

=back

=head2 apply_button_fragment

Renders nothing unless the viewport accepts the C<apply> event.

If it does, it provides the following arguments before rendering C<apply_button>:

=over 4

=item event_id

Is set to the event id C<apply>.

=item label

Is set to the localized C<apply_label> of the viewport.

=back

=head2 cancel_button_fragment

Renders nothing unless the viewport accepts the C<close> event.

If it does, it provides the following arguments before rendering C<cancel_button>:

=over 4

=item event_id

Is set to the event id C<close>.

=item label

Is set to the localized C<close_label> of the viewport.

=back

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/action.tt

The following layouts are provided:

=over 4

=item widget

Renders a C<div> element containing a C<form>. The C<form> element contains the rendered
C<header>, C<container_list>, C<buttons> and C<footer> fragments.

=item header

Renders the error message.

=item container_list

Simply renders the parent C<container_list>.

=item container

Simply renders the parent C<container>.

=item buttons

First renders the C<message> fragment, then the C<ok_button_fragment>, the C<apply_button_fragment>
and the C<cancel_button_fragment>.

=item message_layout

Renders the C<message_string> argument in a C<span> element with an C<action_message> class.

=item error_message_layout

Renders the C<message_string> argument in a C<span> element with an C<action_error_message> class.

=item standard_button

Renders a submit button in a C<span> with the C<name> set to the C<event_id> argument, and the
value set to the C<label> argument.

=item ok_button

Renders the C<standard_button> fragment.

=item apply_button

Renders the C<standard_button> fragment.

=item cancel_button

Renders the C<standard_button> fragment.

=item footer

Empty by default.

=back

=head2 default

  share/skin/base/layout/action.tt

Extends the layout set of the same name in the parent skin.

The following layouts are provided:

=over 4

=item container

Adds a C<br> element after the original C<container> fragment.

=item message_layout

Adds a C<br> element after the original C<message_layout> fragment.

=back

=head1 SEE ALSO

=over 4

=item L<Reaction::UI::Widget::Object::Mutable>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

