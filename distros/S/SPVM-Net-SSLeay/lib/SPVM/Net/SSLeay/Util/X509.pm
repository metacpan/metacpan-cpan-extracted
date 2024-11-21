package SPVM::Net::SSLeay::Util::X509;



1;

=head1 Name

SPVM::Net::SSLeay::Util::X509 - Utilities for X509 Data Structure in OpenSSL

=head1 Description

Net::SSLeay::Util::X509 class in L<SPVM> has utility methods for X509 data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::Util::X509;

=head1 Class Methods

C<static method get_ocsp_uri : string ($cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Returns OCSP URI in the certificate $cert.

If not found, returns undef.

Exceptions:

The X509 object $cert must be defined. Otherwise an exception is thrown.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

