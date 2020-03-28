# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InputContactMessageContent.pm
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
package Net::API::Telegram::InputContactMessageContent;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub first_name { return( shift->_set_get_scalar( 'first_name', @_ ) ); }

sub last_name { return( shift->_set_get_scalar( 'last_name', @_ ) ); }

sub phone_number { return( shift->_set_get_scalar( 'phone_number', @_ ) ); }

sub vcard { return( shift->_set_get_scalar( 'vcard', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InputContactMessageContent - The content of a contact message to be sent as the result of an inline query

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InputContactMessageContent->new( %data ) || 
	die( Net::API::Telegram::InputContactMessageContent->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InputContactMessageContent> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inputcontactmessagecontent>

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

=item B<first_name>( String )

Contact's first name

=item B<last_name>( String )

Optional. Contact's last name

=item B<phone_number>( String )

Contact's phone number

=item B<vcard>( String )

Optional. Additional data about the contact in the form of a vCard, 0-2048 bytes

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

