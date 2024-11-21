package SPVM::Net::SSLeay::Callback::NextProtosAdvertised;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::NextProtosAdvertised - Callback for SSL_CTX_set_next_protos_advertised_cb function in OpenSSL

=head1 Description

Net::SSLeay::Callback::NextProtosAdvertised interface in L<SPVM> representas the callback for native L<SSL_CTX_set_next_protos_advertised_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function in OpenSSL.

=head1 Usage

  interface Net::SSLeay::Callback::NextProtosAdvertised;

=head1 Interface Methods

C<required method : int ($ssl : L<Net::SSLeay|SPVM::Net::SSLeay>, $out : string[], $outlen_ref : int*, $arg : object);>

This method is a callback for native L<SSL_CTX_set_next_protos_advertised_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb/> function in OpenSSL.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
