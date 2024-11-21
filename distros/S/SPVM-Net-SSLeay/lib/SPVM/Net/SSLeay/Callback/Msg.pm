package SPVM::Net::SSLeay::Callback::Msg;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::Msg - Callback for SSL_CTX_set_msg_callback function in OpenSSL

=head1 Description

Net::SSLeay::Callback::Msg interface in L<SPVM> represetns the callback for L<SSL_CTX_set_msg_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_msg_callback> function in OpenSSL.

=head1 Usage

  interface Net::SSLeay::Callback::Msg;

=head1 Interface Methods

=head2 Anon Method

C<required method : void ($write_p : int, $version : int, $content_type : int, $buf : string, $len : int, $ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $arg : object);>

This method is callback for native L<SSL_CTX_set_msg_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_msg_callback> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

