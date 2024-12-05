package SPVM::Net::SSLeay::EVP_MD;



1;

=head1 Name

SPVM::Net::SSLeay::EVP_MD - EVP_MD Data Structure in OpenSSL

=head1 Description

Net::SSLeay::EVP_MD class in L<SPVM> represents L<EVP_MD|https://docs.openssl.org/3.0/man3/EVP_sha224/> Data Structure in OpenSSL

=head1 Usage

  use Net::SSLeay::EVP_MD;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<EVP_MD_free|https://docs.openssl.org/master/man3/EVP_DigestInit/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

Requirement:

OpenSSL 3.0

=head1 See Also

=over 2

=item * L<Net::SSLeay::EVP|SPVM::Net::EVP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

