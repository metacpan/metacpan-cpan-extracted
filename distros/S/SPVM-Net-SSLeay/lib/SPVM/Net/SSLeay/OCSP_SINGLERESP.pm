package SPVM::Net::SSLeay::OCSP_SINGLERESP;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_SINGLERESP - OCSP_SINGLERESP Data Structure in OpenSSL

=head1 Description

Net::SSLeay::OCSP_SINGLERESP class in L<SPVM> represents OCSP_SINGLERESP data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_SINGLERESP;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<OCSP_SINGLERESP_free|https://docs.openssl.org/3.0/man3/X509_dup> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

