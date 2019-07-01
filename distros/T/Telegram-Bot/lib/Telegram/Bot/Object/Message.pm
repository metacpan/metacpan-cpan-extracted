package Telegram::Bot::Object::Message;
$Telegram::Bot::Object::Message::VERSION = '0.021';
# ABSTRACT: The base class for the Telegram type "Message".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;
use Telegram::Bot::Object::Chat;
use Telegram::Bot::Object::MessageEntity;
use Telegram::Bot::Object::Audio;
use Telegram::Bot::Object::Document;
use Telegram::Bot::Object::Animation;
use Telegram::Bot::Object::Game;
use Telegram::Bot::Object::PhotoSize;
use Telegram::Bot::Object::Sticker;
use Telegram::Bot::Object::Video;
use Telegram::Bot::Object::Voice;
use Telegram::Bot::Object::VideoNote;
use Telegram::Bot::Object::Contact;
use Telegram::Bot::Object::Location;
use Telegram::Bot::Object::Poll;
use Telegram::Bot::Object::Location;
use Telegram::Bot::Object::PhotoSize;
use Telegram::Bot::Object::Invoice;
use Telegram::Bot::Object::Venue;
use Telegram::Bot::Object::SuccessfulPayment;
use Telegram::Bot::Object::PassportData;
use Telegram::Bot::Object::InlineKeyboardMarkup;

use Data::Dumper;

# basic message stuff
has 'message_id';
has 'from';  # User
has 'date';
has 'chat';  # Chat

has 'forward_from'; # User
has 'forward_from_chat'; # Chat
has 'forward_from_message_id';
has 'forward_signature';
has 'forward_sender_name';
has 'forward_date';

has 'reply_to_message'; # Message
has 'edit_date';
has 'media_group_id';
has 'author_signature';
has 'text';
has 'entities'; # Array of MessageEntity

has 'caption_entities'; # Array of MessageEntity

has 'audio'; # Audio
has 'document'; # Document
has 'animation'; # Animation
has 'game'; # Game
has 'photo'; # Array of PhotoSize
has 'sticker';  # Sticker
has 'video'; # Video
has 'voice'; # Voice
has 'video_note'; # VideoNote
has 'caption';
has 'contact'; # Contact
has 'location'; # Location
has 'venue'; # Venue
has 'poll'; # Poll
has 'new_chat_members'; # Array of User
has 'left_chat_member'; # User
has 'new_chat_title';
has 'new_chat_photo'; # Array of PhotoSize
has 'delete_chat_photo';
has 'group_chat_created';
has 'supergroup_chat_created';
has 'channel_chat_created';
has 'migrate_to_chat_id';
has 'migrate_from_chat_id';
has 'pinned_message'; # Message
has 'invoice'; # Invoice
has 'successful_payment'; # SuccessfulPayment
has 'connected_website';
has 'passport_data'; # PassportData
has 'reply_markup'; # Array of InlineKeyboardMarkup

sub fields {
  return {
          'scalar'                                      => [qw/message_id date forward_from_message_id
                                                            forward_signature forward_sender_name
                                                            forward_date edit_date media_group_id
                                                            author_signature text caption
                                                            new_chat_title delete_chat_photo
                                                            group_chat_created supergroup_chat_created
                                                            channel_chat_created migrate_to_chat_id
                                                            migrate_from_chat_id connected_website/],
          'Telegram::Bot::Object::User'                 => [qw/from forward_from new_chat_members left_chat_member /],

          'Telegram::Bot::Object::Chat'                 => [qw/chat forward_from_chat/],
          'Telegram::Bot::Object::Message'              => [qw/reply_to_message pinned_message/],
          'Telegram::Bot::Object::MessageEntity'        => [qw/entities caption_entities /],

          'Telegram::Bot::Object::Audio'                => [qw/audio/],
          'Telegram::Bot::Object::Document'             => [qw/document/],
          'Telegram::Bot::Object::Animation'            => [qw/animation/],
          'Telegram::Bot::Object::Game'                 => [qw/game/],
          'Telegram::Bot::Object::PhotoSize'            => [qw/photo new_chat_photo/],
          'Telegram::Bot::Object::Sticker'              => [qw/sticker/],
          'Telegram::Bot::Object::Video'                => [qw/video/],
          'Telegram::Bot::Object::Voice'                => [qw/voice/],
          'Telegram::Bot::Object::VideoNote'            => [qw/video_note/],

          'Telegram::Bot::Object::Contact'              => [qw/contact/],
          'Telegram::Bot::Object::Location'             => [qw/location/],
          'Telegram::Bot::Object::Venue'                => [qw/venue/],

          'Telegram::Bot::Object::Poll'                 => [qw/poll/],

          'Telegram::Bot::Object::Invoice'              => [qw/invoice/],
          'Telegram::Bot::Object::SuccessfulPayment'    => [qw/successful_payment/],
          'Telegram::Bot::Object::PassportData'         => [qw/passport_data/],
          'Telegram::Bot::Object::InlineKeyboardMarkup' => [qw/reply_markup/],

  };
}

sub arrays {
  qw/photo entities caption_entities new_chat_members new_chat_photo/
}


sub reply {
  my $self = shift;
  my $text = shift;
  return $self->_brain->sendMessage({chat_id => $self->chat->id, text => $text});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Message - The base class for the Telegram type "Message".

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#message> for details of the
attributes available for L<Telegram::Bot::Object::Message> objects.

=head1 METHODS

=head2

A convenience method to reply to a message with text.

Will return the L<Telegram::Bot::Object::Message> object representing the message
sent.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
