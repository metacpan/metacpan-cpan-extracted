# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InputMessageContent.pm
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
package Net::API::Telegram::InputMessageContent;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub disable_web_page_preview { return( shift->_set_get_scalar( 'disable_web_page_preview', @_ ) ); }

sub message_text { return( shift->_set_get_scalar( 'message_text', @_ ) ); }

sub parse_mode { return( shift->_set_get_scalar( 'parse_mode', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( disable_web_page_preview ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InputMessageContent - The content of a message to be sent as a result of an inline query

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InputMessageContent->new( %data ) || 
	die( Net::API::Telegram::InputMessageContent->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InputMessageContent> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inputmessagecontent>

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

=item B<disable_web_page_preview>( Boolean )

Optional. Disables link previews for links in the sent message

=item B<message_text>( String )

Text of the message to be sent, 1-4096 characters

=item B<parse_mode>( String )

Optional. Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.

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

