package SPVM::Net::SSLeay::OPENSSL_INIT;



1;

=head1 Name

SPVM::Net::SSLeay::OPENSSL_INIT - OPENSSL_INIT Name Space in OpenSSL

=head1 Description

Net::SSLeay::OPENSSL_INIT class in L<SPVM> represents L<OPENSSL_INIT|https://docs.openssl.org/1.1.1/man3/OPENSSL_init_crypto/> name space in OpenSSL

=head1 Usage

  use Net::SSLeay::OPENSSL_INIT;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS> ();>

Calls native L<OPENSSL_INIT_new|> function, creates a L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 set_config_filename

C<static method set_config_filename : int ($init : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>, $filename : string);>

Calls native L<OPENSSL_INIT_set_config_filename|https://docs.openssl.org/1.1.1/man3/OPENSSL_init_crypto> function given $filename, and returns its return value.

Requirement:

OpenSSL 1.1.1b

Not LibreSSL

Exceptions:

The file name $filename must be defined. Otherwise an exception is thrown.

=head2 set_config_file_flags

C<static method set_config_file_flags : void ($init : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>, $flags : long);>

Calls native L<OPENSSL_INIT_set_config_file_flags|https://docs.openssl.org/1.1.1/man3/OPENSSL_init_crypto> function given $filename.

Requirement:

OpenSSL 3.0.0

Not LibreSSL

=head2 set_config_appname

C<static method set_config_appname : int ($init : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>, $name : string);>

Calls native L<OPENSSL_INIT_set_config_appname|https://docs.openssl.org/1.1.1/man3/OPENSSL_init_crypto> function given $filename, and returns its return value.

Requirement:

OpenSSL 1.1.1b

Not LibreSSL

Exceptions:

The app name $name must be defined. Otherwise an exception is thrown.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>

=item * L<Net::SSLeay::OPENSSL|SPVM::Net::SSLeay::OPENSSL>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
