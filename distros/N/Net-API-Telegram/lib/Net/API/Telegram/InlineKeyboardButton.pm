# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineKeyboardButton.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/05/20
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::InlineKeyboardButton;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub callback_data { return( shift->_set_get_scalar( 'callback_data', @_ ) ); }

sub callback_game { return( shift->_set_get_object( 'callback_game', 'Net::API::Telegram::CallbackGame', @_ ) ); }

sub login_url { return( shift->_set_get_object( 'login_url', 'Net::API::Telegram::LoginUrl', @_ ) ); }

sub pay { return( shift->_set_get_scalar( 'pay', @_ ) ); }

sub switch_inline_query { return( shift->_set_get_scalar( 'switch_inline_query', @_ ) ); }

sub switch_inline_query_current_chat { return( shift->_set_get_scalar( 'switch_inline_query_current_chat', @_ ) ); }

sub text { return( shift->_set_get_scalar( 'text', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( pay ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineKeyboardButton - One button of an inline keyboard

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineKeyboardButton->new( %data ) || 
	die( Net::API::Telegram::InlineKeyboardButton->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineKeyboardButton> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinekeyboardbutton>

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

=item B<callback_data>( String )

Optional. Data to be sent in a callback query to the bot when button is pressed, 1-64 bytes

=item B<callback_game>( L<Net::API::Telegram::CallbackGame> )

Optional. Description of the game that will be launched when the user presses the button.NOTE: This type of button must always be the first button in the first row.

=item B<login_url>( L<Net::API::Telegram::LoginUrl> )

Optional. An HTTP URL used to automatically authorize the user. Can be used as a replacement for the Telegram Login Widget.

=item B<pay>( Boolean )

Optional. Specify True, to send a Pay button.NOTE: This type of button must always be the first button in the first row.

=item B<switch_inline_query>( String )

Optional. If set, pressing the button will prompt the user to select one of their chats, open that chat and insert the bot‘s username and the specified inline query in the input field. Can be empty, in which case just the bot’s username will be inserted.Note: This offers an easy way for users to start using your bot in inline mode when they are currently in a private chat with it. Especially useful when combined with switch_pm… actions – in this case the user will be automatically returned to the chat they switched from, skipping the chat selection screen.

=item B<switch_inline_query_current_chat>( String )

Optional. If set, pressing the button will insert the bot‘s username and the specified inline query in the current chat's input field. Can be empty, in which case only the bot’s username will be inserted.This offers a quick way for the user to open your bot in inline mode in the same chat – good for selecting something from multiple options.

=item B<text>( String )

Label text on the button

=item B<url>( String )

Optional. HTTP or tg:// url to be opened when button is pressed

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

