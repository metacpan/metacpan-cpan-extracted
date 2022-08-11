package SPVM::MIME::Base64;

our $VERSION = '0.05';

1;

=head1 Name

SPVM::MIME::Base64 - Encoding and decoding of base64 strings

=head1 Synopsys

  use MIME::Base64;
  
  my $encoded = MIME::Base64->encode_base64('Aladdin:open sesame');
  my $decoded = MIME::Base64->decode_base64($encoded);

=head1 Description

C<MIME::Base64> is a SPVM module.

This is a porting of L<MIME::Base64> to L<SPVM>.

This module provides functions to encode and decode strings into and from the
base64 encoding specified in RFC 2045 - I<MIME (Multipurpose Internet
Mail Extensions)>.

=head1 Class Methods

The list of class methods.

=head2 encode_base64

  static method encode_base64 : string ($str : string, $eol = undef : string)

Encode data by calling the encode_base64() function.  The first
argument is the byte string to encode.  The second argument is the
line-ending sequence to use.  It is optional and defaults to "\n".  The
returned encoded string is broken into lines of no more than 76
characters each and it will end with $eol unless it is empty.  Pass an
empty string as second argument if you do not want the encoded string
to be broken into lines.

=head2 decode_base64

  static method decode_base64 : string ($str : string)

Decode a base64 string by calling the decode_base64() function.  This
function takes a single argument which is the string to decode and
returns the decoded data.

Any character not part of the 65-character base64 subset is
silently ignored.  Characters occurring after a '=' padding character
are never decoded.

=head2 encoded_base64_length

  static method encoded_base64_length : int ($str : string, $eol = undef : string)

Returns the length that the encoded string would have without actually
encoding it.  This will return the same value as C<< length(&encode_base64($bytes, $eol)) >>,
but should be more efficient.

=head2 decoded_base64_length

  static method decoded_base64_length : int ($str : string)

Returns the length that the decoded string would have without actually
decoding it.  This will return the same value as C<< length(&decode_base64($str)) >>,
but should be more efficient.

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-MIME-Base64>

=head1 Author

Yuki Kimoto (kimoto.yuki@gmail.com)

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 See Also

L<SPVM::MIME::QuotedPrint>
