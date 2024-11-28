package SPVM::Net::SSLeay::ASN1_STRING;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_STRING - ASN1_STRING Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_STRING class in L<SPVM> represents L<ASN1_STRING|https://docs.openssl.org/master/man3/ASN1_STRING_new/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::ASN1_STRING;

=head1 Instance Methods

=head2 length

C<method length : int ();>

Calls native L<ASN1_STRING_length|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, and returns its return value.

=head2 get0_data

C<method get0_data : string ();>

Calls native L<ASN1_STRING_get0_data|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, converts its return value to a string which length is the return value of native L<ASN1_STRING_length|https://docs.openssl.org/1.1.1/man3/ASN1_STRING_length> function, and returns the string.
=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_STRING_free|https://docs.openssl.org/master/man3/ASN1_STRING_new/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

