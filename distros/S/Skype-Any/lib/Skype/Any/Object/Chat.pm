package Skype::Any::Object::Chat;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('CHAT', @_) }
sub alter    { shift->SUPER::alter('CHAT', @_) }

__PACKAGE__->_mk_bool_property(qw/bookmarked/);

sub send_message {
    my ($self, $message) = @_;
    my $command = $self->api->send_command(sprintf 'CHATMESSAGE %s %s', $self->{id}, $message);
    my @reply = $command->split_reply;
    my $id = $reply[1];
    return $self->object(chatmessage => $id);
}

1;
__END__

=head1 NAME

Skype::Any::Object::Chat - Chat object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $chat = $skype->chat($id);

=head1 METHODS

=over 4

=item C<< $chat->send_message($message) >>


Send a message to chat, return instance of Skype::Any::Object::ChatMessage.

=item C<< $chat->property($property[, $value]) >>

=over 4

=item name

=item timestamp

=item adder

=item status

=item posters

=item members

=item topic

=item topicxml

=item chatmessages

=item activemembers

=item friendlyname

=item chatmessages

=item recentchatmessages

=item bookmarked

=item memberobjects

=item passwordhint

=item guidelines

=item options

=item description

=item dialog_partner

=item activity_timestamp

=item type

=item mystatus

=item myrole

=item blob

=item applicants

=back

=item C<< $chat->alter($action[, $value]) >>

=back

=cut
