package SPVM::Net::SSLeay::PEM;



1;

=head1 Name

SPVM::Net::SSLeay::PEM - OpenSSL PEM data structure

=head1 Description

Net::SSLeay::PEM class in L<SPVM> represents C<PEM> name space in OpenSSL.

=head1 Usage

  use Net::SSLeay::PEM;

=head1 Class Methods

=head2 read_bio_X509

C<static method read_bio_X509 : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ($bp : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

Calls native L<PEM_read_bio_X509|https://docs.openssl.org/master/man3/PEM_read_bio_X509> function, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

The BIO $bp must be defined. Otherwise an exception is thrown.

If PEM_read_bio_X509 failed and the error is C<PEM_R_NO_START_LINE>, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error::PEM_R_NO_START_LINE|SPVM::Net::SSLeay::Error::PEM_R_NO_START_LINE> class. If the error is something else, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 read_bio_X509_CRL

C<static method read_bio_X509_CRL : L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL> ($bp : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

Calls native L<PEM_read_bio_X509_CRL|https://docs.openssl.org/master/man3/PEM_read_bio_X509_CRL> function, creates a new L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

The BIO $bp must be defined. Otherwise an exception is thrown.

If PEM_read_bio_X509_CRL failed and the error is C<PEM_R_NO_START_LINE>, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error::PEM_R_NO_START_LINE|SPVM::Net::SSLeay::Error::PEM_R_NO_START_LINE> class. If the error is something else, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 read_bio_PrivateKey

C<static method read_bio_PrivateKey : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY> ($bp : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

Calls native L<PEM_read_bio_PrivateKey|https://docs.openssl.org/master/man3/PEM_read_bio_PrivateKey> function, creates a new L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

The BIO $bp must be defined. Otherwise an exception is thrown.

If PEM_read_bio_PrivateKey failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

