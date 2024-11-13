package SPVM::Net::SSLeay::OCSP_RESPONSE;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_RESPONSE - OCSP_RESPONSE Data Structure in OpenSSL

=head1 Description

Net::SSLeay::OCSP_RESPONSE class in L<SPVM> represents L<OCSP_RESPONSE|https://docs.openssl.org/1.1.1/man3/OCSP_RESPONSE_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_RESPONSE;

=head1 Instance Methods

C<method DESTROY : void ();>

Frees native L<OCSP_RESPONSE|https://docs.openssl.org/1.1.1/man3/X509_dup> object by calling native L<OCSP_RESPONSE_free|https://docs.openssl.org/1.1.1/man3/X509_dup> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OCSP|SPVM::Net::SSLeay::OCSP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
