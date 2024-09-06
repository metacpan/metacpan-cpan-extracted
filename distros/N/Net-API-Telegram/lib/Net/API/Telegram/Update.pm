# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Update.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/06/13
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Update;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub callback_query { return( shift->_set_get_object( 'callback_query', 'Net::API::Telegram::CallbackQuery', @_ ) ); }

sub channel_post { return( shift->_set_get_object( 'channel_post', 'Net::API::Telegram::Message', @_ ) ); }

sub chosen_inline_result { return( shift->_set_get_object( 'chosen_inline_result', 'Net::API::Telegram::ChosenInlineResult', @_ ) ); }

sub edited_channel_post { return( shift->_set_get_object( 'edited_channel_post', 'Net::API::Telegram::Message', @_ ) ); }

sub edited_message { return( shift->_set_get_object( 'edited_message', 'Net::API::Telegram::Message', @_ ) ); }

sub inline_query { return( shift->_set_get_object( 'inline_query', 'Net::API::Telegram::InlineQuery', @_ ) ); }

sub message { return( shift->_set_get_object( 'message', 'Net::API::Telegram::Message', @_ ) ); }

sub poll { return( shift->_set_get_object( 'poll', 'Net::API::Telegram::Poll', @_ ) ); }

sub pre_checkout_query { return( shift->_set_get_object( 'pre_checkout_query', 'Net::API::Telegram::PreCheckoutQuery', @_ ) ); }

sub shipping_query { return( shift->_set_get_object( 'shipping_query', 'Net::API::Telegram::ShippingQuery', @_ ) ); }

sub update_id { return( shift->_set_get_number( 'update_id', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Update - An incoming update.At most one of the optional parameters can be present in any given update

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Update->new( %data ) || 
	die( Net::API::Telegram::Update->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Update> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#update>

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

=item B<callback_query>( L<Net::API::Telegram::CallbackQuery> )

Optional. New incoming callback query

=item B<channel_post>( L<Net::API::Telegram::Message> )

Optional. New incoming channel post of any kind — text, photo, sticker, etc.

=item B<chosen_inline_result>( L<Net::API::Telegram::ChosenInlineResult> )

Optional. The result of an inline query that was chosen by a user and sent to their chat partner. Please see our documentation on the feedback collecting for details on how to enable these updates for your bot.

=item B<edited_channel_post>( L<Net::API::Telegram::Message> )

Optional. New version of a channel post that is known to the bot and was edited

=item B<edited_message>( L<Net::API::Telegram::Message> )

Optional. New version of a message that is known to the bot and was edited

=item B<inline_query>( L<Net::API::Telegram::InlineQuery> )

Optional. New incoming inline query

=item B<message>( L<Net::API::Telegram::Message> )

Optional. New incoming message of any kind — text, photo, sticker, etc.

=item B<poll>( L<Net::API::Telegram::Poll> )

Optional. New poll state. Bots receive only updates about stopped polls and polls, which are sent by the bot

=item B<pre_checkout_query>( L<Net::API::Telegram::PreCheckoutQuery> )

Optional. New incoming pre-checkout query. Contains full information about checkout

=item B<shipping_query>( L<Net::API::Telegram::ShippingQuery> )

Optional. New incoming shipping query. Only for invoices with flexible price

=item B<update_id>( Integer )

The update‘s unique identifier. Update identifiers start from a certain positive number and increase sequentially. This ID becomes especially handy if you’re using Webhooks, since it allows you to ignore repeated updates or to restore the correct update sequence, should they get out of order. If there are no new updates for at least a week, then identifier of the next update will be chosen randomly instead of sequentially.

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

