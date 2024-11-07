package SPVM::Net::SSLeay::X509;



1;

=head1 Name

SPVM::Net::SSLeay::X509 - X509 data structure in OpenSSL

=head1 Description

Net::SSLeay::X509 class in L<SPVM> represents L<X509|https://docs.openssl.org/3.1/man3/X509_new/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509;

=head1 Instance Methods

C<method DESTROY : void ();>

Frees L<X509|https://docs.openssl.org/3.1/man3/X509_new/> object by calling L<X509_free|https://docs.openssl.org/3.1/man3/X509_free/> function if C<no_free> flag of the instance is not a true value.

=head1 FAQ

=head2 How to create a new Net::SSLeay::X509 object?

A way is reading PEM file by calling L<Net::SSLeay::PEM#read_bio_X509|SPVM::Net::SSLeay::PEM/"read_bio_X509"> method.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::PEM>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

