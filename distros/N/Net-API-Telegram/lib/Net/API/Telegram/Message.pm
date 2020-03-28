# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Message.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/03/28
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Message;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub animation { return( shift->_set_get_object( 'animation', 'Net::API::Telegram::Animation', @_ ) ); }

sub audio { return( shift->_set_get_object( 'audio', 'Net::API::Telegram::Audio', @_ ) ); }

sub author_signature { return( shift->_set_get_scalar( 'author_signature', @_ ) ); }

sub caption { return( shift->_set_get_scalar( 'caption', @_ ) ); }

sub caption_entities { return( shift->_set_get_object_array( 'caption_entities', 'Net::API::Telegram::MessageEntity', @_ ) ); }

sub channel_chat_created { return( shift->_set_get_scalar( 'channel_chat_created', @_ ) ); }

sub chat { return( shift->_set_get_object( 'chat', 'Net::API::Telegram::Chat', @_ ) ); }

sub connected_website { return( shift->_set_get_scalar( 'connected_website', @_ ) ); }

sub contact { return( shift->_set_get_object( 'contact', 'Net::API::Telegram::Contact', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }sub delete_chat_photo { return( shift->_set_get_scalar( 'delete_chat_photo', @_ ) ); }

sub document { return( shift->_set_get_object( 'document', 'Net::API::Telegram::Document', @_ ) ); }

sub edit_date { return( shift->_set_get_datetime( 'edit_date', @_ ) ); }sub entities { return( shift->_set_get_object_array( 'entities', 'Net::API::Telegram::MessageEntity', @_ ) ); }

sub forward_date { return( shift->_set_get_datetime( 'forward_date', @_ ) ); }sub forward_from { return( shift->_set_get_object( 'forward_from', 'Net::API::Telegram::User', @_ ) ); }

sub forward_from_chat { return( shift->_set_get_object( 'forward_from_chat', 'Net::API::Telegram::Chat', @_ ) ); }

sub forward_from_message_id { return( shift->_set_get_number( 'forward_from_message_id', @_ ) ); }

sub forward_sender_name { return( shift->_set_get_scalar( 'forward_sender_name', @_ ) ); }

sub forward_signature { return( shift->_set_get_scalar( 'forward_signature', @_ ) ); }

sub from { return( shift->_set_get_object( 'from', 'Net::API::Telegram::User', @_ ) ); }

sub game { return( shift->_set_get_object( 'game', 'Net::API::Telegram::Game', @_ ) ); }

sub group_chat_created { return( shift->_set_get_scalar( 'group_chat_created', @_ ) ); }

sub invoice { return( shift->_set_get_object( 'invoice', 'Net::API::Telegram::Invoice', @_ ) ); }

sub left_chat_member { return( shift->_set_get_object( 'left_chat_member', 'Net::API::Telegram::User', @_ ) ); }

sub location { return( shift->_set_get_object( 'location', 'Net::API::Telegram::Location', @_ ) ); }

sub media_group_id { return( shift->_set_get_scalar( 'media_group_id', @_ ) ); }

sub message_id { return( shift->_set_get_number( 'message_id', @_ ) ); }

sub migrate_from_chat_id { return( shift->_set_get_number( 'migrate_from_chat_id', @_ ) ); }

sub migrate_to_chat_id { return( shift->_set_get_number( 'migrate_to_chat_id', @_ ) ); }

sub new_chat_members { return( shift->_set_get_object_array( 'new_chat_members', 'Net::API::Telegram::User', @_ ) ); }

sub new_chat_photo { return( shift->_set_get_object_array( 'new_chat_photo', 'Net::API::Telegram::PhotoSize', @_ ) ); }

sub new_chat_title { return( shift->_set_get_scalar( 'new_chat_title', @_ ) ); }

sub passport_data { return( shift->_set_get_object( 'passport_data', 'Net::API::Telegram::PassportData', @_ ) ); }

sub photo { return( shift->_set_get_object_array( 'photo', 'Net::API::Telegram::PhotoSize', @_ ) ); }

sub pinned_message { return( shift->_set_get_object( 'pinned_message', 'Net::API::Telegram::Message', @_ ) ); }

sub poll { return( shift->_set_get_object( 'poll', 'Net::API::Telegram::Poll', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub reply_to_message { return( shift->_set_get_object( 'reply_to_message', 'Net::API::Telegram::Message', @_ ) ); }

sub sticker { return( shift->_set_get_object( 'sticker', 'Net::API::Telegram::Sticker', @_ ) ); }

sub successful_payment { return( shift->_set_get_object( 'successful_payment', 'Net::API::Telegram::SuccessfulPayment', @_ ) ); }

sub supergroup_chat_created { return( shift->_set_get_scalar( 'supergroup_chat_created', @_ ) ); }

sub text { return( shift->_set_get_scalar( 'text', @_ ) ); }

sub venue { return( shift->_set_get_object( 'venue', 'Net::API::Telegram::Venue', @_ ) ); }

sub video { return( shift->_set_get_object( 'video', 'Net::API::Telegram::Video', @_ ) ); }

sub video_note { return( shift->_set_get_object( 'video_note', 'Net::API::Telegram::VideoNote', @_ ) ); }

sub voice { return( shift->_set_get_object( 'voice', 'Net::API::Telegram::Voice', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( channel_chat_created delete_chat_photo group_chat_created supergroup_chat_created ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Message - A message

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Message->new( %data ) || 
	die( Net::API::Telegram::Message->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Message> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#message>

This module has been automatically generated from Telegram API documentation by the script scripts/telegram-doc2perl-methods.pl.

=head1 METHODS

=over 4

=item B<new>( {INIT HASH REF}, %PARAMETERS )

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns B<init>().

The valid parameters are as follow. Methods available here are also parameters to the B<new> method.

=over 8

=item * I<verbose>

=item * I<debug>

=back

=item B<animation>( L<Net::API::Telegram::Animation> )

Optional. Message is an animation, information about the animation. For backward compatibility, when this field is set, the document field will also be set

=item B<audio>( L<Net::API::Telegram::Audio> )

Optional. Message is an audio file, information about the file

=item B<author_signature>( String )

Optional. Signature of the post author for messages in channels

=item B<caption>( String )

Optional. Caption for the animation, audio, document, photo, video or voice, 0-1024 characters

=item B<caption_entities>( Array of MessageEntity )

Optional. For messages with a caption, special entities like usernames, URLs, bot commands, etc. that appear in the caption

=item B<channel_chat_created>( True )

Optional. Service message: the channel has been created. This field can‘t be received in a message coming through updates, because bot can’t be a member of a channel when it is created. It can only be found in reply_to_message if someone replies to a very first message in a channel.

=item B<chat>( L<Net::API::Telegram::Chat> )

Conversation the message belongs to

=item B<connected_website>( String )

Optional. The domain name of the website on which the user has logged in. More about Telegram Login »

=item B<contact>( L<Net::API::Telegram::Contact> )

Optional. Message is a shared contact, information about the contact

=item B<date>( Date )

Date the message was sent in Unix time

=item B<delete_chat_photo>( True )

Optional. Service message: the chat photo was deleted

=item B<document>( L<Net::API::Telegram::Document> )

Optional. Message is a general file, information about the file

=item B<edit_date>( Date )

Optional. Date the message was last edited in Unix time

=item B<entities>( Array of MessageEntity )

Optional. For text messages, special entities like usernames, URLs, bot commands, etc. that appear in the text

=item B<forward_date>( Date )

Optional. For forwarded messages, date the original message was sent in Unix time

=item B<forward_from>( L<Net::API::Telegram::User> )

Optional. For forwarded messages, sender of the original message

=item B<forward_from_chat>( L<Net::API::Telegram::Chat> )

Optional. For messages forwarded from channels, information about the original channel

=item B<forward_from_message_id>( Integer )

Optional. For messages forwarded from channels, identifier of the original message in the channel

=item B<forward_sender_name>( String )

Optional. Sender's name for messages forwarded from users who disallow adding a link to their account in forwarded messages

=item B<forward_signature>( String )

Optional. For messages forwarded from channels, signature of the post author if present

=item B<from>( L<Net::API::Telegram::User> )

Optional. Sender, empty for messages sent to channels

=item B<game>( L<Net::API::Telegram::Game> )

Optional. Message is a game, information about the game. More about games »

=item B<group_chat_created>( True )

Optional. Service message: the group has been created

=item B<invoice>( L<Net::API::Telegram::Invoice> )

Optional. Message is an invoice for a payment, information about the invoice. More about payments »

=item B<left_chat_member>( L<Net::API::Telegram::User> )

Optional. A member was removed from the group, information about them (this member may be the bot itself)

=item B<location>( L<Net::API::Telegram::Location> )

Optional. Message is a shared location, information about the location

=item B<media_group_id>( String )

Optional. The unique identifier of a media message group this message belongs to

=item B<message_id>( Integer )

Unique message identifier inside this chat

=item B<migrate_from_chat_id>( Integer )

Optional. The supergroup has been migrated from a group with the specified identifier. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.

=item B<migrate_to_chat_id>( Integer )

Optional. The group has been migrated to a supergroup with the specified identifier. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.

=item B<new_chat_members>( Array of User )

Optional. New members that were added to the group or supergroup and information about them (the bot itself may be one of these members)

=item B<new_chat_photo>( Array of PhotoSize )

Optional. A chat photo was change to this value

=item B<new_chat_title>( String )

Optional. A chat title was changed to this value

=item B<passport_data>( L<Net::API::Telegram::PassportData> )

Optional. Telegram Passport data

=item B<photo>( Array of PhotoSize )

Optional. Message is a photo, available sizes of the photo

=item B<pinned_message>( L<Net::API::Telegram::Message> )

Optional. Specified message was pinned. Note that the Message object in this field will not contain further reply_to_message fields even if it is itself a reply.

=item B<poll>( L<Net::API::Telegram::Poll> )

Optional. Message is a native poll, information about the poll

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message. login_url buttons are represented as ordinary url buttons.

=item B<reply_to_message>( L<Net::API::Telegram::Message> )

Optional. For replies, the original message. Note that the Message object in this field will not contain further reply_to_message fields even if it itself is a reply.

=item B<sticker>( L<Net::API::Telegram::Sticker> )

Optional. Message is a sticker, information about the sticker

=item B<successful_payment>( L<Net::API::Telegram::SuccessfulPayment> )

Optional. Message is a service message about a successful payment, information about the payment. More about payments »

=item B<supergroup_chat_created>( True )

Optional. Service message: the supergroup has been created. This field can‘t be received in a message coming through updates, because bot can’t be a member of a supergroup when it is created. It can only be found in reply_to_message if someone replies to a very first message in a directly created supergroup.

=item B<text>( String )

Optional. For text messages, the actual UTF-8 text of the message, 0-4096 characters.

=item B<venue>( L<Net::API::Telegram::Venue> )

Optional. Message is a venue, information about the venue

=item B<video>( L<Net::API::Telegram::Video> )

Optional. Message is a video, information about the video

=item B<video_note>( L<Net::API::Telegram::VideoNote> )

Optional. Message is a video note, information about the video message

=item B<voice>( L<Net::API::Telegram::Voice> )

Optional. Message is a voice message, information about the file

=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

