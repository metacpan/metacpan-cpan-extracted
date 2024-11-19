package SPVM::Net::SSLeay::Callback::TlsextStatus;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::TlsextStatus - Callback for SSL_CTX_set_tlsext_status_cb function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::TlsextStatus interface in L<SPVM> is the callback for L<SSL_CTX_set_tlsext_status_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_status_cb> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::TlsextStatus;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $arg : object);>

This method is callback for native L<SSL_CTX_set_tlsext_status_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_status_cb> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

