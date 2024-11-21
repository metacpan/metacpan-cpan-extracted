package SPVM::Net::SSLeay::HMAC_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::HMAC_CTX - HMAC_CTX Data Structure in OpenSSL

=head1 Description

Net::SSLeay::HMAC_CTX class in L<SPVM> represetns L<HMAC_CTX|https://docs.openssl.org/3.1/man3/HMAC/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::HMAC_CTX;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<HMAC_CTX_free|https://docs.openssl.org/3.1/man3/HMAC/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

