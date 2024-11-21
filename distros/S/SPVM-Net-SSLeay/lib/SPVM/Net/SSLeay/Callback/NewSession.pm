package SPVM::Net::SSLeay::Callback::NewSession;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::NewSession - Callback for SSL_CTX_sess_set_new_cb function in OpenSSL.

=head1 Description

Net::SSLeay::Callback::NewSession interface in L<SPVM> is the callback for L<SSL_CTX_sess_set_new_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_sess_set_get_cb/> function in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::NewSession;

=head1 Interface Methods

=head2 Anon Method

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $session : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION>);>

This method is the callback for native L<SSL_CTX_sess_set_new_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_sess_set_get_cb/> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

