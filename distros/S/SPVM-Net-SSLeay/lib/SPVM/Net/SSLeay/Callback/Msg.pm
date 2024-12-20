package SPVM::Net::SSLeay::Callback::Msg;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::Msg - Function Pointer Type of SSL_CTX_set_msg_callback function's Callback Argument in OpenSSL

=head1 Description

Net::SSLeay::Callback::Msg interface in L<SPVM> represents the function pointer type of L<SSL_CTX_set_msg_callback|https://docs.openssl.org/master/man3/SSL_CTX_set_msg_callback> function's callback argument in OpenSSL.

=head1 Usage

  interface Net::SSLeay::Callback::Msg;

=head1 Interface Methods

=head2 Anon Method

C<required method : void ($write_p : int, $version : int, $content_type : int, $buf : string, $len : int, $ssl : L<Net::SSLeay|SPVM::Net::SSLeay>);>

This method represents the function pointer type of L<SSL_CTX_set_msg_callback|https://docs.openssl.org/master/man3/SSL_CTX_set_msg_callback> function's callback argument in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

