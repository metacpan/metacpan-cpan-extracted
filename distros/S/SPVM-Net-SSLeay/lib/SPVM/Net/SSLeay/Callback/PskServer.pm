package SPVM::Net::SSLeay::Callback::PskServer;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::PskServer - Callback for SSL_CTX_set_psk_server_callback function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::PskServer interface in L<SPVM> is the callback for L<SSL_CTX_set_psk_server_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_psk_identity_hint/> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::PskServer;

=head1 Interface Methods

=head2 Anon Method

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $identity : string, $identity_len : int, $sess_ref : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION>[]);>

This method is callback for native L<SSL_CTX_set_psk_server_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_psk_identity_hint/> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

