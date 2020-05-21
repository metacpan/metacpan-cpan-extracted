# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/CallbackQuery.pm
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
package Net::API::Telegram::CallbackQuery;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub chat_instance { return( shift->_set_get_scalar( 'chat_instance', @_ ) ); }

sub data { return( shift->_set_get_scalar( 'data', @_ ) ); }

sub from { return( shift->_set_get_object( 'from', 'Net::API::Telegram::User', @_ ) ); }

sub game_short_name { return( shift->_set_get_scalar( 'game_short_name', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub inline_message_id { return( shift->_set_get_scalar( 'inline_message_id', @_ ) ); }

sub message { return( shift->_set_get_object( 'message', 'Net::API::Telegram::Message', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::CallbackQuery - An incoming callback query from a callback button in an inline keyboard

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::CallbackQuery->new( %data ) || 
	die( Net::API::Telegram::CallbackQuery->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::CallbackQuery> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#callbackquery>

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

=item B<chat_instance>( String )

Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent. Useful for high scores in games.

=item B<data>( String )

Optional. Data associated with the callback button. Be aware that a bad client can send arbitrary data in this field.

=item B<from>( L<Net::API::Telegram::User> )

Sender

=item B<game_short_name>( String )

Optional. Short name of a Game to be returned, serves as the unique identifier for the game

=item B<id>( String )

Unique identifier for this query

=item B<inline_message_id>( String )

Optional. Identifier of the message sent via the bot in inline mode, that originated the query.

=item B<message>( L<Net::API::Telegram::Message> )

Optional. Message with the callback button that originated the query. Note that message content and message date will not be available if the message is too old

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

