package SPVM::Net::SSLeay::OCSP_CERTID;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_CERTID - OCSP_CERTID Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::OCSP_CERTID class in L<SPVM> represents L<OCSP_CERTID|https://docs.openssl.org/1.1.1/man3/OCSP_cert_to_id/> data strucutre in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_CERTID;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Frees native L<OCSP_CERTID|https://docs.openssl.org/1.1.1/man3/OCSP_cert_to_id/> object by calling native L<OCSP_CERTID_free|https://docs.openssl.org/1.1.1/man3/OCSP_cert_to_id/> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

