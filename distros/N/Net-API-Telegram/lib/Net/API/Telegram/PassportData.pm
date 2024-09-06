# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/PassportData.pm
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
package Net::API::Telegram::PassportData;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub credentials { return( shift->_set_get_object( 'credentials', 'Net::API::Telegram::EncryptedCredentials', @_ ) ); }

sub data { return( shift->_set_get_object_array( 'data', 'Net::API::Telegram::EncryptedPassportElement', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::PassportData - Information about Telegram Passport data shared with the bot by the user

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::PassportData->new( %data ) || 
	die( Net::API::Telegram::PassportData->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::PassportData> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#passportdata>

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

=item B<credentials>( L<Net::API::Telegram::EncryptedCredentials> )

Encrypted credentials required to decrypt the data

=item B<data>( Array of EncryptedPassportElement )

Array with information about documents and other Telegram Passport elements that was shared with the bot

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

