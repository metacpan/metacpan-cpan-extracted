package SPVM::Net::SSLeay::X509_VERIFY_PARAM;



1;

=head1 Name

SPVM::Net::SSLeay::X509_VERIFY_PARAM - X509_VERIFY_PARAM data structure in OpenSSL.

=head1 Description

Net::SSLeay::X509_VERIFY_PARAM class in L<SPVM> represents L<X509_VERIFY_PARAM|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_VERIFY_PARAM;

=head1 Instance Methods

=head2 set_hostflags

C<method set_hostflags : void ($flags : int);>

Sets the host flags to $flags by calling L<X509_VERIFY_PARAM_set_hostflags|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function.

=head2 set1_host

C<method set1_host : int ($name : string, $namelen : int = 0);>

Sets the host name $name of the length $namelen by calling L<X509_VERIFY_PARAM_set1_host|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function.

If $namelen is 0, it is set to the length of $name.

Exceptions:

The host name $name must be defined. Otherwise an exception is thrown.

The length $namelen must be greater than or equal to the length of the host name $name. Otherwise an exception is thrown.

=head2 DESTROY

C<method DESTROY : void ();>

Frees L<X509_VERIFY_PARAM|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> object by calling L<X509_VERIFY_PARAM_free|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function if C<no_free> flag of the instance is not a true value.

=head1 FAQ

=head2 How to get a Net::SSLeay::X509_VERIFY_PARAM object?

A way is using L<Net::SSLeay::SSL_CTX#get0_param|SPVM::Net::SSLeay::SSL_CTX/"get0_param"> method.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

