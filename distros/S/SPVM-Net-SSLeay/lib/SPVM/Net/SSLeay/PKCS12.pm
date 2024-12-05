package SPVM::Net::SSLeay::PKCS12;



1;

=head1 Name

SPVM::Net::SSLeay::PKCS12 - PKCS12 Data Structure in OpenSSL

=head1 Description

Net::SSLeay::PKCS12 class in L<SPVM> represents L<PKCS12|https://docs.openssl.org/master/man3/X509_dup> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::PKCS12;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::PKCS12|SPVM::Net::SSLeay::PKCS12> ();>

Calls native L<PKCS12_new|https://docs.openssl.org/master/man3/X509_dup> function, creates a new  L<Net::SSLeay::PKCS12|SPVM::Net::SSLeay::PKCS12> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If PKCS12_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 parse

C<method parse : int ($pass : string, $pkey_ref : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>[], $cert_ref : L<Net::SSLeay::X509[]|SPVM::Net::SSLeay::X509>, $cas_ref : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[][] = undef);>

Calls native L<PKCS12_parse|https://docs.openssl.org/master/man3/PKCS12_parse/> function given $pass, apprepriate arguments for rest arguments.

And creates a new L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>, sets the pointer value of the new object to the value of the corresponding output argument of the native function, sets C<$pkey_ref->[0]> to the new object.

And creates a new L<Net::SSLeay::X509[]|SPVM::Net::SSLeay::X509>, sets the pointer value of the new object to the value of the output corresponding argument of the native function, sets C<$cert_ref->[0]> to the new object.

And creates a new array of L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> from the value of the output corresponding argument of the native function, sets C<$cas_ref->[0]> to the new array.

And returns the return value of the native function.

Exceptions:

The 1-length array $pkey_ref for output for a private key must be defined. Otherwise an exception is thrown.

The 1-length array $cert_ref for output for a certificate must be defined. Otherwise an exception is thrown.

The 1-length array $cas_ref for output for intermediate certificate must be defined if defined. Otherwise an exception is thrown.

If PKCS12_parse failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<PKCS12_free|https://docs.openssl.org/master/man3/X509_dup/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

