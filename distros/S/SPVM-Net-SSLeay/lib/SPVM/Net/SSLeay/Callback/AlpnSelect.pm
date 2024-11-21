package SPVM::Net::SSLeay::Callback::AlpnSelect;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::AlpnSelect - Callback for SSL_CTX_set_alpn_select_cb function in OpenSSL

=head1 Description

Net::SSLeay::Callback::AlpnSelect interface in L<SPVM> represetns the callback for L<SSL_CTX_set_alpn_select_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function in OpenSSL.

=head1 Usage

  interface Net::SSLeay::Callback::AlpnSelect;

=head1 Interface Methods

=head2 Anon Method

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $out_ref : string[], $outlen_ref : int*, $in : string, $inlen : int, $arg : object);>

This method is callback for native L<SSL_CTX_set_alpn_select_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

