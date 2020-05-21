# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ChatPermissions.pm
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
package Net::API::Telegram::ChatPermissions;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub can_add_web_page_previews { return( shift->_set_get_scalar( 'can_add_web_page_previews', @_ ) ); }

sub can_change_info { return( shift->_set_get_scalar( 'can_change_info', @_ ) ); }

sub can_invite_users { return( shift->_set_get_scalar( 'can_invite_users', @_ ) ); }

sub can_pin_messages { return( shift->_set_get_scalar( 'can_pin_messages', @_ ) ); }

sub can_send_media_messages { return( shift->_set_get_scalar( 'can_send_media_messages', @_ ) ); }

sub can_send_messages { return( shift->_set_get_scalar( 'can_send_messages', @_ ) ); }

sub can_send_other_messages { return( shift->_set_get_scalar( 'can_send_other_messages', @_ ) ); }

sub can_send_polls { return( shift->_set_get_scalar( 'can_send_polls', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( can_add_web_page_previews can_change_info can_invite_users can_pin_messages can_send_media_messages can_send_messages can_send_other_messages can_send_polls ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ChatPermissions - Describes actions that a non-administrator user is allowed to take in a chat

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ChatPermissions->new( %data ) || 
	die( Net::API::Telegram::ChatPermissions->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ChatPermissions> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#chatpermissions>

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

Optional. True, if the user is allowed to add web page previews to their messages, implies can_send_media_messages

=item B<can_change_info>( Boolean )

Optional. True, if the user is allowed to change the chat title, photo and other settings. Ignored in public supergroups

=item B<can_invite_users>( Boolean )

Optional. True, if the user is allowed to invite new users to the chat

=item B<can_pin_messages>( Boolean )

Optional. True, if the user is allowed to pin messages. Ignored in public supergroups

=item B<can_send_media_messages>( Boolean )

Optional. True, if the user is allowed to send audios, documents, photos, videos, video notes and voice notes, implies can_send_messages

=item B<can_send_messages>( Boolean )

Optional. True, if the user is allowed to send text messages, contacts, locations and venues

=item B<can_send_other_messages>( Boolean )

Optional. True, if the user is allowed to send animations, games, stickers and use inline bots, implies can_send_media_messages

=item B<can_send_polls>( Boolean )

Optional. True, if the user is allowed to send polls, implies can_send_messages

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

