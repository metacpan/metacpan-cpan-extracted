package SPVM::Net::SSLeay::Callback::PskClient;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::PskClient - Callback for SSL_CTX_set_psk_client_callback function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::PskClient interface in L<SPVM> is the callback for L<SSL_CTX_set_psk_client_callback|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_psk_client_callback> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::PskClient;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $hint : string, $identity : mutable string, $max_identity_len : int, $psk : mutable string, $max_psk_len : int);>

This method is callback for native L<SSL_CTX_set_psk_client_callback|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_psk_client_callback> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

