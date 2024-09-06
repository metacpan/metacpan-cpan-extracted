# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ChatMember.pm
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
package Net::API::Telegram::ChatMember;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub can_add_web_page_previews { return( shift->_set_get_scalar( 'can_add_web_page_previews', @_ ) ); }

sub can_be_edited { return( shift->_set_get_scalar( 'can_be_edited', @_ ) ); }

sub can_change_info { return( shift->_set_get_scalar( 'can_change_info', @_ ) ); }

sub can_delete_messages { return( shift->_set_get_scalar( 'can_delete_messages', @_ ) ); }

sub can_edit_messages { return( shift->_set_get_scalar( 'can_edit_messages', @_ ) ); }

sub can_invite_users { return( shift->_set_get_scalar( 'can_invite_users', @_ ) ); }

sub can_pin_messages { return( shift->_set_get_scalar( 'can_pin_messages', @_ ) ); }

sub can_post_messages { return( shift->_set_get_scalar( 'can_post_messages', @_ ) ); }

sub can_promote_members { return( shift->_set_get_scalar( 'can_promote_members', @_ ) ); }

sub can_restrict_members { return( shift->_set_get_scalar( 'can_restrict_members', @_ ) ); }

sub can_send_media_messages { return( shift->_set_get_scalar( 'can_send_media_messages', @_ ) ); }

sub can_send_messages { return( shift->_set_get_scalar( 'can_send_messages', @_ ) ); }

sub can_send_other_messages { return( shift->_set_get_scalar( 'can_send_other_messages', @_ ) ); }

sub can_send_polls { return( shift->_set_get_scalar( 'can_send_polls', @_ ) ); }

sub is_member { return( shift->_set_get_scalar( 'is_member', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub until_date { return( shift->_set_get_datetime( 'until_date', @_ ) ); }sub user { return( shift->_set_get_object( 'user', 'Net::API::Telegram::User', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( can_add_web_page_previews can_be_edited can_change_info can_delete_messages can_edit_messages can_invite_users can_pin_messages can_post_messages can_promote_members can_restrict_members can_send_media_messages can_send_messages can_send_other_messages can_send_polls is_member ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ChatMember - Information about one member of a chat

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ChatMember->new( %data ) || 
	die( Net::API::Telegram::ChatMember->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ChatMember> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#chatmember>

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

=item B<can_add_web_page_previews>( Boolean )

Optional. Restricted only. True, if the user is allowed to add web page previews to their messages

=item B<can_be_edited>( Boolean )

Optional. Administrators only. True, if the bot is allowed to edit administrator privileges of that user

=item B<can_change_info>( Boolean )

Optional. Administrators and restricted only. True, if the user is allowed to change the chat title, photo and other settings

=item B<can_delete_messages>( Boolean )

Optional. Administrators only. True, if the administrator can delete messages of other users

=item B<can_edit_messages>( Boolean )

Optional. Administrators only. True, if the administrator can edit messages of other users and can pin messages; channels only

=item B<can_invite_users>( Boolean )

Optional. Administrators and restricted only. True, if the user is allowed to invite new users to the chat

=item B<can_pin_messages>( Boolean )

Optional. Administrators and restricted only. True, if the user is allowed to pin messages; groups and supergroups only

=item B<can_post_messages>( Boolean )

Optional. Administrators only. True, if the administrator can post in the channel; channels only

=item B<can_promote_members>( Boolean )

Optional. Administrators only. True, if the administrator can add new administrators with a subset of his own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by the user)

=item B<can_restrict_members>( Boolean )

Optional. Administrators only. True, if the administrator can restrict, ban or unban chat members

=item B<can_send_media_messages>( Boolean )

Optional. Restricted only. True, if the user is allowed to send audios, documents, photos, videos, video notes and voice notes

=item B<can_send_messages>( Boolean )

Optional. Restricted only. True, if the user is allowed to send text messages, contacts, locations and venues

=item B<can_send_other_messages>( Boolean )

Optional. Restricted only. True, if the user is allowed to send animations, games, stickers and use inline bots

=item B<can_send_polls>( Boolean )

Optional. Restricted only. True, if the user is allowed to send polls

=item B<is_member>( Boolean )

Optional. Restricted only. True, if the user is a member of the chat at the moment of the request

=item B<status>( String )

The member's status in the chat. Can be I<creator>, I<administrator>, I<member>, I<restricted>, I<left> or I<kicked>

=item B<until_date>( Date )

Optional. Restricted and kicked only. Date when restrictions will be lifted for this user; unix time

=item B<user>( L<Net::API::Telegram::User> )

Information about the user

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

