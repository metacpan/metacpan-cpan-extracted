# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/LoginUrl.pm
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
package Net::API::Telegram::LoginUrl;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub bot_username { return( shift->_set_get_scalar( 'bot_username', @_ ) ); }

sub forward_text { return( shift->_set_get_scalar( 'forward_text', @_ ) ); }

sub request_write_access { return( shift->_set_get_scalar( 'request_write_access', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( request_write_access ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::LoginUrl - A parameter of the inline keyboard button used to automatically authorize a user

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::LoginUrl->new( %data ) || 
	die( Net::API::Telegram::LoginUrl->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::LoginUrl> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#loginurl>

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

=item B<bot_username>( String )

Optional. Username of a bot, which will be used for user authorization. See Setting up a bot for more details. If not specified, the current bot's username will be assumed. The url's domain must be the same as the domain linked with the bot. See Linking your domain to the bot for more details.

=item B<forward_text>( String )

Optional. New text of the button in forwarded messages.

=item B<request_write_access>( Boolean )

Optional. Pass True to request the permission for your bot to send messages to the user.

=item B<url>( String )

An HTTP URL to be opened with user authorization data added to the query string when the button is pressed. If the user refuses to provide authorization data, the original URL without information about the user will be opened. The data added is the same as described in Receiving authorization data.NOTE: You must always check the hash of the received data to verify the authentication and the integrity of the data as described in Checking authorization.

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

