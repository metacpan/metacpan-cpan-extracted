package SPVM::Net::SSLeay::OCSP_ONEREQ;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_ONEREQ - OCSP_ONEREQ Data Structure in OpenSSL.

=head1 Description

Net::SSLeay::OCSP_ONEREQ class in L<SPVM> represents L<OCSP_ONEREQ|https://docs.openssl.org/3.0/man3/OCSP_REQUEST_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_ONEREQ;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<OCSP_ONEREQ_free|https://docs.openssl.org/3.1/man3/X509_dup> function given the pointer of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OCSP|SPVM::Net::SSLeay::OCSP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

