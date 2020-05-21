# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultVenue.pm
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
package Net::API::Telegram::InlineQueryResultVenue;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub address { return( shift->_set_get_scalar( 'address', @_ ) ); }

sub foursquare_id { return( shift->_set_get_scalar( 'foursquare_id', @_ ) ); }

sub foursquare_type { return( shift->_set_get_scalar( 'foursquare_type', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub input_message_content { return( shift->_set_get_object( 'input_message_content', 'Net::API::Telegram::InputMessageContent', @_ ) ); }

sub latitude { return( shift->_set_get_number( 'latitude', @_ ) ); }

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

Net::API::Telegram::InlineQueryResultVenue - A venue

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultVenue->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultVenue->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultVenue> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultvenue>

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

=item B<address>( String )

Address of the venue

=item B<foursquare_id>( String )

Optional. Foursquare identifier of the venue if known

=item B<foursquare_type>( String )

Optional. Foursquare type of the venue, if known. (For example, I<arts_entertainment/default>, I<arts_entertainment/aquarium> or I<food/icecream>.)

=item B<id>( String )

Unique identifier for this result, 1-64 Bytes

=item B<input_message_content>( L<Net::API::Telegram::InputMessageContent> )

Optional. Content of the message to be sent instead of the venue

=item B<latitude>( Float )

Latitude of the venue location in degrees

=item B<longitude>( Float )

Longitude of the venue location in degrees

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<thumb_height>( Integer )

Optional. Thumbnail height

=item B<thumb_url>( String )

Optional. Url of the thumbnail for the result

=item B<thumb_width>( Integer )

Optional. Thumbnail width

=item B<title>( String )

Title of the venue

=item B<type>( String )

Type of the result, must be venue

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

