package SPVM::Net::SSLeay::X509_STORE;



1;

=head1 Name

SPVM::Net::SSLeay::X509_STORE - X509_STORE

=head1 Description

Net::SSLeay::X509_STORE in L<SPVM> represetns C<X509_STORE> structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_STORE;

=head1 Instance Methods

=head2 add_cert

C<method add_cert : int ($x : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

=head2 set_flags

C<method set_flags : void ($flags : long);>

=head2 add_crl

C<mmethod add_crl : void ($x : L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL>);>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

