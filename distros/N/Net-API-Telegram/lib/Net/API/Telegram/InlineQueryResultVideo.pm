# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultVideo.pm
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
package Net::API::Telegram::InlineQueryResultVideo;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub caption { return( shift->_set_get_scalar( 'caption', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub input_message_content { return( shift->_set_get_object( 'input_message_content', 'Net::API::Telegram::InputMessageContent', @_ ) ); }

sub mime_type { return( shift->_set_get_scalar( 'mime_type', @_ ) ); }

sub parse_mode { return( shift->_set_get_scalar( 'parse_mode', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub thumb_url { return( shift->_set_get_scalar( 'thumb_url', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub video_duration { return( shift->_set_get_number( 'video_duration', @_ ) ); }

sub video_height { return( shift->_set_get_number( 'video_height', @_ ) ); }

sub video_url { return( shift->_set_get_scalar( 'video_url', @_ ) ); }

sub video_width { return( shift->_set_get_number( 'video_width', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineQueryResultVideo - A link to a page containing an embedded video player or a video file

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultVideo->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultVideo->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultVideo> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultvideo>

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

=item B<caption>( String )

Optional. Caption of the video to be sent, 0-1024 characters

=item B<description>( String )

Optional. Short description of the result

=item B<id>( String )

Unique identifier for this result, 1-64 bytes

=item B<input_message_content>( L<Net::API::Telegram::InputMessageContent> )

Optional. Content of the message to be sent instead of the video. This field is required if InlineQueryResultVideo is used to send an HTML-page as a result (e.g., a YouTube video).

=item B<mime_type>( String )

Mime type of the content of video url, I<text/html> or I<video/mp4>

=item B<parse_mode>( String )

Optional. Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<thumb_url>( String )

URL of the thumbnail (jpeg only) for the video

=item B<title>( String )

Title for the result

=item B<type>( String )

Type of the result, must be video

=item B<video_duration>( Integer )

Optional. Video duration in seconds

=item B<video_height>( Integer )

Optional. Video height

=item B<video_url>( String )

A valid URL for the embedded video player or video file

=item B<video_width>( Integer )

Optional. Video width

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

