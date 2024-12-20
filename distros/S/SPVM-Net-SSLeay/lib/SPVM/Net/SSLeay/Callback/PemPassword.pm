package SPVM::Net::SSLeay::Callback::PemPassword;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::PemPassword - pem_password_cb Function Pointer Type in OpenSSL..

=head1 Description

Net::SSLeay::Callback::PemPassword interface in L<SPVM> represents L<pem_password_cb|https://docs.openssl.org/master/man3/pem_password_cb> function pointer type in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::PemPassword;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $rwflag : int);>

This method represents L<pem_password_cb|https://docs.openssl.org/master/man3/pem_password_cb> function pointer type in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

