# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Chat.pm
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
package Net::API::Telegram::Chat;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub can_set_sticker_set { return( shift->_set_get_scalar( 'can_set_sticker_set', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub first_name { return( shift->_set_get_scalar( 'first_name', @_ ) ); }

sub id { return( shift->_set_get_number( 'id', @_ ) ); }

sub invite_link { return( shift->_set_get_scalar( 'invite_link', @_ ) ); }

sub last_name { return( shift->_set_get_scalar( 'last_name', @_ ) ); }

sub permissions { return( shift->_set_get_object( 'permissions', 'Net::API::Telegram::ChatPermissions', @_ ) ); }

sub photo { return( shift->_set_get_object( 'photo', 'Net::API::Telegram::ChatPhoto', @_ ) ); }

sub pinned_message { return( shift->_set_get_object( 'pinned_message', 'Net::API::Telegram::Message', @_ ) ); }

sub sticker_set_name { return( shift->_set_get_scalar( 'sticker_set_name', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub username { return( shift->_set_get_scalar( 'username', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( can_set_sticker_set ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Chat - A chat

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Chat->new( %data ) || 
	die( Net::API::Telegram::Chat->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Chat> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#chat>

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

=item B<can_set_sticker_set>( Boolean )

Optional. True, if the bot can change the group sticker set. Returned only in getChat.

=item B<description>( String )

Optional. Description, for groups, supergroups and channel chats. Returned only in getChat.

=item B<first_name>( String )

Optional. First name of the other party in a private chat

=item B<id>( Integer )

Unique identifier for this chat. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.

=item B<invite_link>( String )

Optional. Chat invite link, for groups, supergroups and channel chats. Each administrator in a chat generates their own invite links, so the bot must first generate the link using exportChatInviteLink. Returned only in getChat.

=item B<last_name>( String )

Optional. Last name of the other party in a private chat

=item B<permissions>( L<Net::API::Telegram::ChatPermissions> )

Optional. Default chat member permissions, for groups and supergroups. Returned only in getChat.

=item B<photo>( L<Net::API::Telegram::ChatPhoto> )

Optional. Chat photo. Returned only in getChat.

=item B<pinned_message>( L<Net::API::Telegram::Message> )

Optional. Pinned message, for groups, supergroups and channels. Returned only in getChat.

=item B<sticker_set_name>( String )

Optional. For supergroups, name of group sticker set. Returned only in getChat.

=item B<title>( String )

Optional. Title, for supergroups, channels and group chats

=item B<type>( String )

Type of chat, can be either I<private>, I<group>, I<supergroup> or I<channel>

=item B<username>( String )

Optional. Username, for private chats, supergroups and channels if available

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

