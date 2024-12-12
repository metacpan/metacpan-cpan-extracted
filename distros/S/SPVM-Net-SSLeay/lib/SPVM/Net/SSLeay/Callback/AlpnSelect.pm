package SPVM::Net::SSLeay::Callback::AlpnSelect;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::AlpnSelect - Function Pointer Type of SSL_CTX_set_alpn_select_cb function's Callback Argument in OpenSSL

=head1 Description

Net::SSLeay::Callback::AlpnSelect interface in L<SPVM> represents the function pointer type of L<SSL_CTX_set_alpn_select_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function's callback argument in OpenSSL.

=head1 Usage

  interface Net::SSLeay::Callback::AlpnSelect;

=head1 Interface Methods

=head2 Anon Method

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $out_ref : string[], $outlen_ref : byte*, $in : string, $inlen : int, $arg : object);>

This method represents the function pointer type of L<SSL_CTX_set_alpn_select_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function's callback argument in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

