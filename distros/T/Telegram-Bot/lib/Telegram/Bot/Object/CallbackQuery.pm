package Telegram::Bot::Object::CallbackQuery;
$Telegram::Bot::Object::CallbackQuery::VERSION = '0.029';
# ABSTRACT: The base class for the Telegram type "CallbackQuery".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;
use Telegram::Bot::Object::Message;

use Data::Dumper;

# basic message stuff
has 'id'; # String
has 'from';  # User
has 'message'; # Message

has 'inline_message_id'; # String
has 'chat_instance'; # String
has 'data'; # String

has 'game_short_name'; # String

sub fields {
  return {
          'scalar'                                      => [qw/id inline_message_id chat_instance data game_short_name/],
          'Telegram::Bot::Object::User'                 => [qw/from/],

          'Telegram::Bot::Object::Message'              => [qw/message/],
  };
}

sub arrays {
}


sub answer {
  my $self = shift;
  my $text = shift;
  return $self->_brain->answerCallbackQuery({callback_query_id => $self->id, text => $text, cache_time => 3600});
}

sub reply {
    my $self = shift;
    my $text = shift;
    return $self->message->reply($text);
}

sub chat {
  my $self = shift;
  return $self->message->chat;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::CallbackQuery - The base class for the Telegram type "CallbackQuery".

=head1 VERSION

version 0.029

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#callbackquery> for details of the
attributes available for L<Telegram::Bot::Object::CallbackQuery> objects.

=head1 METHODS

=head2

A convenience method to respond to a keyboard prompt.

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
