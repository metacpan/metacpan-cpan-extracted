package SPVM::Net::SSLeay::EVP;



1;

=head1 Name

SPVM::Net::SSLeay::EVP - EVP Name Space in OpenSSL

=head1 Description

Net::SSLeay::EVP class in L<SPVM> represents L<EVP|https://docs.openssl.org/3.1/man3/EVP_DigestInit> Name Space in OpenSSL.

=head1 Usage

  use Net::SSLeay::EVP;

=head1 Class Methods

=head2 get_digestbyname

C<static method get_digestbyname : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> ($name : string);>

Calls native L<EVP_get_digestbyname|https://docs.openssl.org/3.1/man3/EVP_DigestInit/> function given $name.

If the return value is not NULL, returns undef.

Otherwise, creates a L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

=head2 sha1

C<static method sha1 : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> ();>

Calls native L<EVP_sha1|https://docs.openssl.org/1.1.1/man3/EVP_sha1/> function, creates a L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

=head2 sha256

C<static method sha256 : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> ();>

Calls native L<EVP_sha256|https://docs.openssl.org/1.1.1/man3/EVP_sha256/> function, creates a L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

=head2 sha512

C<static method sha512 : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> ();>

Calls native L<EVP_sha512|https://docs.openssl.org/1.1.1/man3/EVP_sha512/> function, creates a L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

=head1 See Also

=over 2

=item * L<Net::SSLeay::EVP_MD|SPVM::Net::EVP_MD>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

