package SPVM::Net::SSLeay::Callback::PskClient;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::PskClient - Function Pointer Type of SSL_CTX_set_psk_server_callback function's Callback Argument in OpenSSL.

=head1 Description

Net::SSLeay::Callback::PskClient interface in L<SPVM> represents the function pointer type of L<SSL_CTX_set_psk_server_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_psk_identity_hint> function's callback argument in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::PskClient;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $identity : string, $identity_len : int, $sess_ref : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION>[]);>

This method represents the function pointer type of L<SSL_CTX_set_psk_server_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_psk_identity_hint> function's callback argument in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

