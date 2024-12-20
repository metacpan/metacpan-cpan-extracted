package SPVM::Net::SSLeay::X509_REVOKED;



1;

=head1 Name

SPVM::Net::SSLeay::X509_REVOKED - X509_REVOKED Data Strucuture in OpenSSL

=head1 Description

Net::SSLeay::X509_REVOKED class in L<SPVM> represents C<X509_REVOKED> data strucuture in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_REVOKED;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509_REVOKED|SPVM::Net::SSLeay::X509_REVOKED> ();>

Calls native L<X509_REVOKED_new|https://docs.openssl.org/master/man3/X509_REVOKED_new> function, creates a new  L<Net::SSLeay::X509_REVOKED|SPVM::Net::SSLeay::X509_REVOKED> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_REVOKED_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 get0_serialNumber

C<method get0_serialNumber : L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER> ();>

Calls native L<X509_REVOKED_get0_serialNumber|https://docs.openssl.org/master/man3/X509_REVOKED_get0_serialNumber> function given the pointer value of the instance, copies the return value of the native function using native L<ASN1_INTEGER_dup|https://docs.openssl.org/master/man3/ASN1_INTEGER_dup> function, creates a new L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER> ojbect, sets the pointer value of the new object to the native copied value, and returns the new object.

=head2 get0_revocationDate

C<method get0_revocationDate : L<Net::SSLeay::ASN1_TIME|SPVM::Net::SSLeay::ASN1_TIME> ();>

Calls native L<X509_REVOKED_get0_revocationDate|https://docs.openssl.org/master/man3/X509_REVOKED_get0_revocationDate> function given the pointer value of the instance, copies the return value of the native function using native L<ASN1_STRING_dup|https://docs.openssl.org/master/man3/ASN1_STRING_dup> function, creates a new L<Net::SSLeay::ASN1_TIME|SPVM::Net::SSLeay::ASN1_TIME> ojbect, sets the pointer value of the new object to the native copied value, and returns the new object.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_REVOKED_free|https://docs.openssl.org/master/man3/X509_REVOKED_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509_REVOKED|SPVM::Net::SSLeay::X509_REVOKED>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

