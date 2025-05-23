# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultVoice.pm
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
package Net::API::Telegram::InlineQueryResultVoice;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub caption { return( shift->_set_get_scalar( 'caption', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub input_message_content { return( shift->_set_get_object( 'input_message_content', 'Net::API::Telegram::InputMessageContent', @_ ) ); }

sub parse_mode { return( shift->_set_get_scalar( 'parse_mode', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub voice_duration { return( shift->_set_get_number( 'voice_duration', @_ ) ); }

sub voice_url { return( shift->_set_get_scalar( 'voice_url', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineQueryResultVoice - A link to a voice recording in an .ogg container encoded with OPUS

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultVoice->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultVoice->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultVoice> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultvoice>

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

Optional. Caption, 0-1024 characters

=item B<id>( String )

Unique identifier for this result, 1-64 bytes

=item B<input_message_content>( L<Net::API::Telegram::InputMessageContent> )

Optional. Content of the message to be sent instead of the voice recording

=item B<parse_mode>( String )

Optional. Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<title>( String )

Recording title

=item B<type>( String )

Type of the result, must be voice

=item B<voice_duration>( Integer )

Optional. Recording duration in seconds

=item B<voice_url>( String )

A valid URL for the voice recording

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

