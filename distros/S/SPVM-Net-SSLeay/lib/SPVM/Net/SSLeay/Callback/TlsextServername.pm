package SPVM::Net::SSLeay::Callback::TlsextServername;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::TlsextServername - Callback for SSL_CTX_set_tlsext_servername_callback function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::TlsextServername interface in L<SPVM> is the callback for L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::TlsextServername;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $al_ref : int*, $arg : object);>

This method is callback for native L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

