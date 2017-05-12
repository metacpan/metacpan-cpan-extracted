package Skype::Any::Object::ChatMessage;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('CHATMESSAGE', @_) }

__PACKAGE__->_mk_bool_property(qw/is_editable/);

sub user {
    my $self = shift;
    my $from_handle = $self->property('from_handle');
    return $self->object(user => $from_handle);
}

sub chat {
    my $self = shift;
    my $chatname = $self->property('chatname');
    return $self->object(chat => $chatname);
}

1;
__END__

=head1 NAME

Skype::Any::Object::ChatMessage - ChatMessage object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $chatmessage = $skype->chatmessage($id);

=head1 METHODS

=over 4

=item C<< $chatmessage->user() >>

Get user object who sent a message.

=item C<< $chatmessage->chat() >>

Get chat object from message has been sent.

=item C<< $chatmessage->property($property[, $value]) >>

=over 4

=item timestamp

=item from_handle

=item from_dispname

=item type

=item status

=item leavereason

=item chatname

=item users

=item is_editable

=item edited_by

=item edited_timestamp

=item options

=item role

=item seen

=item body

=back

=back

=cut
