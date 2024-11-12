package SPVM::Net::SSLeay::EVP_PKEY;



1;

=head1 Name

SPVM::Net::SSLeay::EVP_PKEY - EVP_PKEY Data Structure in OpenSSL

=head1 Description

Net::SSLeay::EVP_PKEY class in L<SPVM> represents L<EVP_PKEY|https://docs.openssl.org/3.0/man3/EVP_PKEY_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::EVP_PKEY;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Frees native L<EVP_PKEY|https://docs.openssl.org/3.0/man3/EVP_PKEY_new/> object by calling native L<EVP_PKEY_free|https://docs.openssl.org/3.0/man3/EVP_PKEY_new/> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::EVP|SPVM::Net::EVP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

