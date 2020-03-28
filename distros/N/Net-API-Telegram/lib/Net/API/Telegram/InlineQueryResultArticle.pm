# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultArticle.pm
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
package Net::API::Telegram::InlineQueryResultArticle;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub hide_url { return( shift->_set_get_scalar( 'hide_url', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub input_message_content { return( shift->_set_get_object( 'input_message_content', 'Net::API::Telegram::InputMessageContent', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub thumb_height { return( shift->_set_get_number( 'thumb_height', @_ ) ); }

sub thumb_url { return( shift->_set_get_scalar( 'thumb_url', @_ ) ); }

sub thumb_width { return( shift->_set_get_number( 'thumb_width', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( hide_url ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineQueryResultArticle - A link to an article or web page

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultArticle->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultArticle->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultArticle> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultarticle>

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

=item B<description>( String )

Optional. Short description of the result

=item B<hide_url>( Boolean )

Optional. Pass True, if you don't want the URL to be shown in the message

=item B<id>( String )

Unique identifier for this result, 1-64 Bytes

=item B<input_message_content>( L<Net::API::Telegram::InputMessageContent> )

Content of the message to be sent

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<thumb_height>( Integer )

Optional. Thumbnail height

=item B<thumb_url>( String )

Optional. Url of the thumbnail for the result

=item B<thumb_width>( Integer )

Optional. Thumbnail width

=item B<title>( String )

Title of the result

=item B<type>( String )

Type of the result, must be article

=item B<url>( String )

Optional. URL of the result

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

