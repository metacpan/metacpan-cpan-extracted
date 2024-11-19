package SPVM::Net::SSLeay::OCSP_BASICRESP;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_BASICRESP - OCSP_BASICRESP Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::OCSP_BASICRESP class in L<SPVM> represents L<OCSP_BASICRESP|https://docs.openssl.org/1.1.1/man3/OCSP_response_status/> data strucutre in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_BASICRESP;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<OCSP_BASICRESP_free|https://docs.openssl.org/1.1.1/man3/X509_dup> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

