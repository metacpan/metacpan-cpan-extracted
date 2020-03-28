# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InputMedia.pm
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
package Net::API::Telegram::InputMedia;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub caption { return( shift->_set_get_scalar( 'caption', @_ ) ); }

sub media { return( shift->_set_get_scalar( 'media', @_ ) ); }

sub parse_mode { return( shift->_set_get_scalar( 'parse_mode', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InputMedia - The content of a media message to be sent

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InputMedia->new( %data ) || 
	die( Net::API::Telegram::InputMedia->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InputMedia> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inputmedia>

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

Optional. Caption of the photo to be sent, 0-1024 characters

=item B<media>( String )

File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass I<attach://<file_attach_name>> to upload a new one using multipart/form-data under <file_attach_name> name. More info on Sending Files »

=item B<parse_mode>( String )

Optional. Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item B<type>( String )

Type of the result, must be photo

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

