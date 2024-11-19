package SPVM::Net::SSLeay::DH;



1;

=head1 Name

SPVM::Net::SSLeay::DH - DH Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::DH class in L<SPVM> represents L<DH|https://docs.openssl.org/3.0/man3/DH_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::DH;

=head1 Class Methods



=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<DH_free|https://docs.openssl.org/3.0/man3/DH_new/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

