package SPVM::Net::SSLeay::EVP_MD;



1;

=head1 Name

SPVM::Net::SSLeay::EVP_MD - EVP_MD Data Structure in OpenSSL

=head1 Description

Net::SSLeay::EVP_MD class in L<SPVM> represents C<EVP_MD> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::EVP_MD;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<EVP_MD_free|https://docs.openssl.org/master/man3/EVP_MD_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

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

