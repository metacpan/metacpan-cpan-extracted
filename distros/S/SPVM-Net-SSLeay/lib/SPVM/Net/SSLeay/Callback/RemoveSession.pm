package SPVM::Net::SSLeay::Callback::RemoveSession;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::RemoveSession - Function Pointer Type of SSL_CTX_sess_set_remove_cb function's Callback Argument in OpenSSL.

=head1 Description

Net::SSLeay::Callback::RemoveSession interface in L<SPVM> represents the function pointer type of L<SSL_CTX_sess_set_remove_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_sess_set_get_cb/> function's callback argument in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::RemoveSession;

=head1 Interface Methods

=head2 Anon Method

C<required method : void ($ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>, $session : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION>);>

This method represents the function pointer type of L<SSL_CTX_sess_set_remove_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_sess_set_get_cb/> function's callback argument in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

