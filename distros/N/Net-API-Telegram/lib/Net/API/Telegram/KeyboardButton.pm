# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/KeyboardButton.pm
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
package Net::API::Telegram::KeyboardButton;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub request_contact { return( shift->_set_get_scalar( 'request_contact', @_ ) ); }

sub request_location { return( shift->_set_get_scalar( 'request_location', @_ ) ); }

sub text { return( shift->_set_get_scalar( 'text', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( request_contact request_location ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::KeyboardButton - One button of the reply keyboard

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::KeyboardButton->new( %data ) || 
	die( Net::API::Telegram::KeyboardButton->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::KeyboardButton> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#keyboardbutton>

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

=item B<request_contact>( Boolean )

Optional. If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only

=item B<request_location>( Boolean )

Optional. If True, the user's current location will be sent when the button is pressed. Available in private chats only

=item B<text>( String )

Text of the button. If none of the optional fields are used, it will be sent as a message when the button is pressed

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

