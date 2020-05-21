# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/WebhookInfo.pm
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
package Net::API::Telegram::WebhookInfo;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub allowed_updates { return( shift->_set_get_array( 'allowed_updates',  ) ); }

sub has_custom_certificate { return( shift->_set_get_scalar( 'has_custom_certificate', @_ ) ); }

sub last_error_date { return( shift->_set_get_datetime( 'last_error_date', @_ ) ); }sub last_error_message { return( shift->_set_get_scalar( 'last_error_message', @_ ) ); }

sub max_connections { return( shift->_set_get_number( 'max_connections', @_ ) ); }

sub pending_update_count { return( shift->_set_get_number( 'pending_update_count', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( has_custom_certificate ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::WebhookInfo - Information about the current status of a webhook

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::WebhookInfo->new( %data ) || 
	die( Net::API::Telegram::WebhookInfo->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::WebhookInfo> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#webhookinfo>

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

=item B<allowed_updates>( Array of String )

Optional. A list of update types the bot is subscribed to. Defaults to all update types

=item B<has_custom_certificate>( Boolean )

True, if a custom certificate was provided for webhook certificate checks

=item B<last_error_date>( Date )

Optional. Unix time for the most recent error that happened when trying to deliver an update via webhook

=item B<last_error_message>( String )

Optional. Error message in human-readable format for the most recent error that happened when trying to deliver an update via webhook

=item B<max_connections>( Integer )

Optional. Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery

=item B<pending_update_count>( Integer )

Number of updates awaiting delivery

=item B<url>( String )

Webhook URL, may be empty if webhook is not set up

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

