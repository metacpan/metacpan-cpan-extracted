# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultLocation.pm
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
package Net::API::Telegram::InlineQueryResultLocation;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub input_message_content { return( shift->_set_get_object( 'input_message_content', 'Net::API::Telegram::InputMessageContent', @_ ) ); }

sub latitude { return( shift->_set_get_number( 'latitude', @_ ) ); }

sub live_period { return( shift->_set_get_number( 'live_period', @_ ) ); }

sub longitude { return( shift->_set_get_number( 'longitude', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub thumb_height { return( shift->_set_get_number( 'thumb_height', @_ ) ); }

sub thumb_url { return( shift->_set_get_scalar( 'thumb_url', @_ ) ); }

sub thumb_width { return( shift->_set_get_number( 'thumb_width', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineQueryResultLocation - A location on a map

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultLocation->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultLocation->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultLocation> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultlocation>

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

=item B<id>( String )

Unique identifier for this result, 1-64 Bytes

=item B<input_message_content>( L<Net::API::Telegram::InputMessageContent> )

Optional. Content of the message to be sent instead of the location

=item B<latitude>( Float number )

Location latitude in degrees

=item B<live_period>( Integer )

Optional. Period in seconds for which the location can be updated, should be between 60 and 86400.

=item B<longitude>( Float number )

Location longitude in degrees

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<thumb_height>( Integer )

Optional. Thumbnail height

=item B<thumb_url>( String )

Optional. Url of the thumbnail for the result

=item B<thumb_width>( Integer )

Optional. Thumbnail width

=item B<title>( String )

Location title

=item B<type>( String )

Type of the result, must be location

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

