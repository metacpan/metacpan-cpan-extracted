package SPVM::Net::SSLeay::Callback::TlsextTicketKey;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::TlsextTicketKey - Callback for SSL_CTX_set_tlsext_ticket_key_cb function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::TlsextTicketKey interface in L<SPVM> is the callback for L<SSL_CTX_set_tlsext_ticket_key_cb|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_tlsext_ticket_key_cb> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::TlsextTicketKey;

=head1 Interface Methods

=head2 Anon Method

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $identity : string, $identity_len : int, $sess_ref : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION>[]);>

This method is callback for native L<SSL_CTX_set_tlsext_ticket_key_cb|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_tlsext_ticket_key_cb> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

