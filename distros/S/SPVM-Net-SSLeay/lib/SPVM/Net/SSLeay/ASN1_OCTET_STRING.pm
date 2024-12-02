package SPVM::Net::SSLeay::ASN1_OCTET_STRING;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_OCTET_STRING - ASN1_OCTET_STRING Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_OCTET_STRING class in L<SPVM> represents L<ASN1_OCTET_STRING|https://pub.sortix.org/sortix/release/nightly/man/man3/ASN1_OCTET_STRING_free.3.html> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::ASN1_OCTET_STRING;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING> ();>

Calls native L<ASN1_OCTET_STRING_new|https://docs.openssl.org/1.0.2/man3/ASN1_OCTET_STRING_new/> function, creates a new  L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If ASN1_OCTET_STRING_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 length

C<method length : int ();>

Calls native L<ASN1_STRING_length|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, and returns its return value.

=head2 get0_data

C<method get0_data : string ();>

Calls native L<ASN1_STRING_get0_data|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, converts its return value to a string which length is the return value of native L<ASN1_STRING_length|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, and returns the string.

=head2 set

C<method set : void ($data : string, $len : int = -1);>

Calls native L<ASN1_STRING_set|https://docs.openssl.org/3.3/man3/ASN1_STRING_length/> function given the pointer value of the instance, $data, $len,.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_OCTET_STRING_free|https://pub.sortix.org/sortix/release/nightly/man/man3/ASN1_OCTET_STRING_free.3.html> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

