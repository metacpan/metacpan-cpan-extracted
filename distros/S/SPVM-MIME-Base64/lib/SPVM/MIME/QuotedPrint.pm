package SPVM::MIME::QuotedPrint;

1;

=head1 Name

SPVM::MIME::QuotedPrint - Encoding and decoding of quoted-printable strings

=head1 Synopsys

  use MIME::QuotedPrint;
  
  my $encoded = MIME::QuotedPrint->encode_qp($decoded);
  my $decoded = MIME::QuotedPrint->decode_qp($encoded);

=head1 Description

C<MIME::QuotedPrint> is a L<SPVM> module to encoding and decoding of quoted-printable strings.

This is a porting of L<MIME::QuotedPrint> to L<SPVM>.

This module provides functions to encode and decode strings into and from the
quoted-printable encoding specified in RFC 2045 - I<MIME (Multipurpose
Internet Mail Extensions)>.

=head1 Caution

L<SPVM> is yet experimental status.

=head1 Class Methods

The list of class methods.

=head2 encode_qp

  static method encode_qp : string ($str : string);

=head2 encode_qp_opt

  static method encode_qp_opt : string ($str : string, $eol : string, $binmode : int);

This function returns an encoded version of the string ($str) given as
argument.

The second argument ($eol) is the line-ending sequence to use.  It is
optional(C<undef> can be specified) and defaults to "\n".  Every occurrence of "\n" is replaced
with this string, and it is also used for additional "soft line
breaks" to ensure that no line end up longer than 76 characters.  Pass
it as "\015\012" to produce data suitable for external consumption.
The string "\r\n" produces the same result on many platforms, but not
all.

The third argument ($binmode) will select binary mode if passed as a
TRUE value.  In binary mode "\n" will be encoded in the same way as
any other non-printable character.  This ensures that a decoder will
end up with exactly the same string whatever line ending sequence it
uses.  In general it is preferable to use the base64 encoding for
binary data; see L<MIME::Base64>.

An $eol of "" (the empty string) is special.  In this case, no "soft
line breaks" are introduced and binary mode is effectively enabled so
that any "\n" in the original data is encoded as well.

=head2 decode_qp
  
  static method decode_qp : string ($str : string);

This function returns the plain text version of the string given
as argument.  The lines of the result are "\n" terminated, even if
the $str argument contains "\r\n" terminated lines.

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-MIME-Base64>

=head1 Author

Yuki Kimoto (kimoto.yuki@gmail.com)

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 See Also

L<SPVM::MIME::Base64>
