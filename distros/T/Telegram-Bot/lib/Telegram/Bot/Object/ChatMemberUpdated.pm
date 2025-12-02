package Telegram::Bot::Object::ChatMemberUpdated;
$Telegram::Bot::Object::ChatMemberUpdated::VERSION = '0.029';
# ABSTRACT: The base class for the Telegram type "ChatMemberUpdated".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::ChatMember;

use Data::Dumper;

# basic message stuff

has 'chat'; # Chat
has 'from'; # User
has 'date';  # Integer
has 'new_chat_member';                  # ChatMember
has 'old_chat_member';                  # ChatMember
has 'invite_link';                      # ChatInviteLink
has 'via_join_request';                 # boolean
has 'via_chat_folder_invite_link';      # boolean

sub fields {
  return {
          'scalar'                                      => [qw/date via_join_request via_chat_folder_invite_link/],
          'Telegram::Bot::Object::User'                 => [qw/from/],
          'Telegram::Bot::Object::Chat'                 => [qw/chat/],
          'Telegram::Bot::Object::ChatMember'           => [qw/new_chat_member old_chat_member /],
  };
}

sub arrays {
}


sub approve {
  my $self = shift;
  my $text = shift;
  return $self->_brain->approveChatMemberUpdated({chat_id => $self->chat->id, user_id => $self->from->id});
}

sub decline {
  my $self = shift;
  my $text = shift;
  return $self->_brain->declineChatMemberUpdated({chat_id => $self->chat->id, user_id => $self->from->id});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ChatMemberUpdated - The base class for the Telegram type "ChatMemberUpdated".

=head1 VERSION

version 0.029

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chatmemberupdated> for details of the
attributes available for L<Telegram::Bot::Object::ChatMemberUpdated> objects.

=head1 METHODS

=head2

Convenience methods

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=item *

Julien Fiegehenn <simbabque@cpan.org>

=item *

Jess Robinson <jrobinson@cpan.org>

=item *

Albert Cester <albert.cester@web.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
