package Telegram::Bot::Object::ChatJoinRequest;
$Telegram::Bot::Object::ChatJoinRequest::VERSION = '0.027';
# ABSTRACT: The base class for the Telegram type "ChatJoinRequest".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;
use Telegram::Bot::Object::Chat;
use Telegram::Bot::Object::ChatInviteLink;

use Data::Dumper;

# basic message stuff
has 'chat'; # Chat
has 'from'; # User

has 'user_chat_id'; # Integer
has 'date';  # Integer
has 'bio'; # String
has 'invite_link'; # ChatInviteLink

sub fields {
  return {
          'scalar'                                      => [qw/user_chat_id date bio/],
          'Telegram::Bot::Object::User'                 => [qw/from/],

          'Telegram::Bot::Object::Chat'                 => [qw/chat/],

          'Telegram::Bot::Object::ChatInviteLink'       => [qw/invite_link/],
  };
}

sub arrays {
}


sub approve {
  my $self = shift;
  my $text = shift;
  return $self->_brain->approveChatJoinRequest({chat_id => $self->chat->id, user_id => $self->from->id});
}

sub decline {
  my $self = shift;
  my $text = shift;
  return $self->_brain->declineChatJoinRequest({chat_id => $self->chat->id, user_id => $self->from->id});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ChatJoinRequest - The base class for the Telegram type "ChatJoinRequest".

=head1 VERSION

version 0.027

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chatjoinrequest> for details of the
attributes available for L<Telegram::Bot::Object::ChatJoinRequest> objects.

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
