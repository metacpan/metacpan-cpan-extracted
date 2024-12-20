package SPVM::Net::SSLeay::SSL_METHOD;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_METHOD - SSL_METHOD data structure in OpenSSL

=head1 Description

Net::SSLeay::SSL_METHOD class in L<SPVM> represents C<SSL_METHOD> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::SSL_METHOD;

=head1 Class Methods

=head2 TLS_method

C<static method TLS_method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> ();>

Calls native L<TLS_method|https://docs.openssl.org/master/man3/TLS_method> function, creates a new L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> object, sets the pointer value of the new object to the return value of L<TLS_method|https://docs.openssl.org/master/man3/TLS_method> function, and returns the new object.

=head2 TLS_client_method

C<static method TLS_client_method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> ();>

Calls native L<TLS_client_method|https://docs.openssl.org/master/man3/TLS_client_method> function, creates a new L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> object, sets the pointer value of the new object to the return value of L<TLS_client_method|https://docs.openssl.org/master/man3/TLS_client_method> function, and returns the new object.

=head2 TLS_server_method

C<static method TLS_server_method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> ();>

Calls native L<TLS_server_method|https://docs.openssl.org/master/man3/TLS_server_method> function, creates a new L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> object, sets the pointer value of the new object to the return value of L<TLS_server_method|https://docs.openssl.org/master/man3/TLS_server_method> function, and returns the new object.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back


=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

