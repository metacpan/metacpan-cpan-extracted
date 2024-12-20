package SPVM::Net::SSLeay::OPENSSL;



1;

=head1 Name

SPVM::Net::SSLeay::OPENSSL - OPENSSL(or OpenSSL) Name Space in OpenSSL

=head1 Description

Net::SSLeay::OPENSSL class in L<SPVM> represetns C<OPENSSL> and C<OpenSSL> name space in OpenSSL.

=head1 Usage

  use Net::SSLeay::OPENSSL;

=head1 Class Methods

=head2 add_ssl_algorithms

C<static method add_ssl_algorithms : int ();>

Calls native L<OpenSSL_add_ssl_algorithms|https://docs.openssl.org/master/man3/OpenSSL_add_ssl_algorithms> function.

=head2 add_all_algorithms

C<add_all_algorithms : void();>

Calls native L<OpenSSL_add_all_algorithms|https://docs.openssl.org/master/man3/OpenSSL_add_all_algorithms> function.

=head2 init_crypto

C<static method init_crypto : int ($opts : long, $settings : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>);>

Calls native L<OPENSSL_init_crypto|https://docs.openssl.org/master/man3/OPENSSL_init_crypto> function, and returns its return value.

Exceptions:

If OpenSSL_init_crypto failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 init_ssl

C<static method init_ssl : int ($opts : long, $settings : L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>);>

Calls native L<OPENSSL_init_ssl|https://docs.openssl.org/master/man3/OPENSSL_init_ssl> function, and returns its return value.

Exceptions:

If OpenSSL_init_ssl failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

