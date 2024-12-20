package SPVM::Net::SSLeay::Util;



1;

=head1 Name

SPVM::Net::SSLeay::Util - Utilitiy Methods for OpenSSL

=head1 Description

Net::SSLeay::Util class in L<SPVM> has utility methods for OpenSSL.

=head1 Usage

  use Net::SSLeay::Util;

=head1 Class Methods

=head2 convert_to_wire_format

C<static method convert_to_wire_format : byte[] ($protocols : string[]);>

Converts to the protocols $protocols to a L<wire format|https://docs.openssl.org/master/man3/SSL_CTX_set_alpn_select_cb>, and returns it.

Exceptions:

The protocols $protocols must be defined. Otherwise an exception is thrown.

The element of the protocols $protocols at index $i must be defined. Otherwise an exception is thrown.

The element of the protocols $protocols at index $i must be a non-empty string. Otherwise an exception is thrown.

The string lenght of the element of the protocols $protocols at index $i must be less than or equal to 255. Otherwise an exception is thrown.

($i is the index of the element of $protocols)

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
