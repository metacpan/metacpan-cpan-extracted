package SPVM::Net::SSLeay::Callback::Verify;



1;

=head1 Name

SPVM::Net::SSLeay::Callback::Verify - SSL_verify_cb Function Pointer Type in OpenSSL.

=head1 Description

Net::SSLeay::Callback::Verify interface in L<SPVM> represents L<SSL_verify_cb|https://docs.openssl.org/master/man3/SSL_CTX_set_verify/> function pointer type in OpenSSL.

=head1 Usage

  use Net::SSLeay::Callback::Verify;

=head1 Interface Methods

C<required method : int ($preverify_ok : int, $x509_store_ctx : L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>);>

This method represents L<SSL_verify_cb|https://docs.openssl.org/master/man3/SSL_CTX_set_verify/> function pointer type.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

