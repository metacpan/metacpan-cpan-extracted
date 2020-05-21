# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/EncryptedPassportElement.pm
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
package Net::API::Telegram::EncryptedPassportElement;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub data { return( shift->_set_get_scalar( 'data', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub files { return( shift->_set_get_object_array( 'files', 'Net::API::Telegram::PassportFile', @_ ) ); }

sub front_side { return( shift->_set_get_object( 'front_side', 'Net::API::Telegram::PassportFile', @_ ) ); }

sub hash { return( shift->_set_get_scalar( 'hash', @_ ) ); }

sub phone_number { return( shift->_set_get_scalar( 'phone_number', @_ ) ); }

sub reverse_side { return( shift->_set_get_object( 'reverse_side', 'Net::API::Telegram::PassportFile', @_ ) ); }

sub selfie { return( shift->_set_get_object( 'selfie', 'Net::API::Telegram::PassportFile', @_ ) ); }

sub translation { return( shift->_set_get_object_array( 'translation', 'Net::API::Telegram::PassportFile', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::EncryptedPassportElement - Information about documents or other Telegram Passport elements shared with the bot by the user

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::EncryptedPassportElement->new( %data ) || 
	die( Net::API::Telegram::EncryptedPassportElement->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::EncryptedPassportElement> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#encryptedpassportelement>

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

=item B<data>( String )

Optional. Base64-encoded encrypted Telegram Passport element data provided by the user, available for I<personal_details>, I<passport>, I<driver_license>, I<identity_card>, I<internal_passport> and I<address> types. Can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<email>( String )

Optional. User's verified email address, available only for I<email> type

=item B<files>( Array of PassportFile )

Optional. Array of encrypted files with documents provided by the user, available for I<utility_bill>, I<bank_statement>, I<rental_agreement>, I<passport_registration> and I<temporary_registration> types. Files can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<front_side>( L<Net::API::Telegram::PassportFile> )

Optional. Encrypted file with the front side of the document, provided by the user. Available for I<passport>, I<driver_license>, I<identity_card> and I<internal_passport>. The file can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<hash>( String )

Base64-encoded element hash for using in PassportElementErrorUnspecified

=item B<phone_number>( String )

Optional. User's verified phone number, available only for I<phone_number> type

=item B<reverse_side>( L<Net::API::Telegram::PassportFile> )

Optional. Encrypted file with the reverse side of the document, provided by the user. Available for I<driver_license> and I<identity_card>. The file can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<selfie>( L<Net::API::Telegram::PassportFile> )

Optional. Encrypted file with the selfie of the user holding a document, provided by the user; available for I<passport>, I<driver_license>, I<identity_card> and I<internal_passport>. The file can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<translation>( Array of PassportFile )

Optional. Array of encrypted files with translated versions of documents provided by the user. Available if requested for I<passport>, I<driver_license>, I<identity_card>, I<internal_passport>, I<utility_bill>, I<bank_statement>, I<rental_agreement>, I<passport_registration> and I<temporary_registration> types. Files can be decrypted and verified using the accompanying EncryptedCredentials.

=item B<type>( String )

Element type. One of I<personal_details>, I<passport>, I<driver_license>, I<identity_card>, I<internal_passport>, I<address>, I<utility_bill>, I<bank_statement>, I<rental_agreement>, I<passport_registration>, I<temporary_registration>, I<phone_number>, I<email>.

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

