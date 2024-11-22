package SPVM::Net::SSLeay::ASN1_OBJECT;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_OBJECT - ASN1_OBJECT Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_OBJECT class in L<SPVM> represents L<ASN1_OBJECT|https://docs.openssl.org/master/man3/OBJ_nid2obj> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::ASN1_OBJECT;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_OBJECT_free|https://docs.openssl.org/3.1/man3/ASN1_OBJECT_new/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OBJ|SPVM::Net::SSLeay::OBJ>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

