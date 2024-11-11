package SPVM::Net::SSLeay::OPENSSL;



1;

=head1 Name

SPVM::Net::SSLeay::OPENSSL - OPENSSL(or OpenSSL) Name Space in OpenSSL

=head1 Description

Net::SSLeay::OPENSSL class in L<SPVM> represetns L<OPENSSL|https://docs.openssl.org/1.1.1/man3/OPENSSL_init_ssl>(or OpenSSL) Name Space in OpenSSL.

=head1 Usage

  use Net::SSLeay::OPENSSL;

=head1 Class Methods

=head2 add_ssl_algorithms

C<static method add_ssl_algorithms : int ();>

Calls L<OpenSSL_add_ssl_algorithms|https://docs.openssl.org/1.1.1/man3/SSL_library_init> function, and returns its return value.

=head2 add_all_algorithms

C<add_all_algorithms : void();>

Calls L<OpenSSL_add_all_algorithms|https://docs.openssl.org/1.1.1/man3/SSL_library_init> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

