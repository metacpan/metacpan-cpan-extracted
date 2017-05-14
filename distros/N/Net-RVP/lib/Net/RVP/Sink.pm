=head1 NAME

Net::RVP::Sink - base clase for RVP event sinks

=head1 DESCRIPTION

These methods are invoked on your event sink object.

=cut
package Net::RVP::Sink;

use strict;

use HTTP::Status;


=head2 new

Create new sink object; called only if user doesn't provide a sink.

=cut
sub new {
  my $class = shift;
  return bless {}, ref $class || $class;
}


=head2 RVP

Set/get RVP object.

=cut
sub RVP {
  my $self = shift;
  $self->{rvp} = shift if @_;
  return $self->{rvp};
}


=head2 change_event ( RVP::User, ( key => value ) ... )

Property change event.

=cut
sub change_event {
  return HTTP::Response->new(RC_OK, 'Change Notification Accepted');
}


=head2 open_event ( RVP::Session )

Starting a new conversation (incoming only, not notified of ones we begin).
This doesn't need to return anything.

=cut
sub open_event {
  # do nothing
}


=head2 close_event ( RVP::Session )

Ending (or leaving) a session.

=cut
sub close_event {
  # do nothing
}


=head2 join_event ( RVP::Session, RVP::User )

New user joining conversation.

=cut
sub join_event {
  return HTTP::Response->new(RC_OK, 'User Joined Conversation');
}


=head2 part_event ( RVP::Session, RVP::User )

User left conversation.

=cut
sub part_event {
  return HTTP::Response->new(RC_OK, 'User Left Conversation');
}


=head2 typing_event ( RVP::Session, RVP::User )

User is typing.

=cut
sub typing_event {
  return HTTP::Response->new(RC_OK, 'User Is Typing');
}


=head2 message_event ( RVP::Session, RVP::User, text )

User sent message.

=cut
sub message_event {
  return HTTP::Response->new(RC_OK, 'Message Received');
}


=head1 AUTHOR

David Robins E<lt>dbrobins@davidrobins.netE<gt>.

=head1 SEE ALSO

L<RVP>.

=cut


1;

