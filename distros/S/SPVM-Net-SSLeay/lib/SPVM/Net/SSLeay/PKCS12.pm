package SPVM::Net::SSLeay::PKCS12;



1;

=head1 Name

SPVM::Net::SSLeay::PKCS12 - PKCS12 Data Structure in OpenSSL

=head1 Description

Net::SSLeay::PKCS12 class in L<SPVM> represents PKCS12 data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::PKCS12;

=head1 Instance Methods

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

