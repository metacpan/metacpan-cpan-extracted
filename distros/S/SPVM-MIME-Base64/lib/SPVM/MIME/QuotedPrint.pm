package SPVM::MIME::QuotedPrint;

1;

=head1 Name

SPVM::MIME::QuotedPrint - Quoted-Printable Encoding/Decoding

=head1 Description

The MIME::QuotedPrint class of L<SPVM> has methods for Quoted-Printable encoding/decoding.

=head1 Usage

  use MIME::QuotedPrint;
  
  my $encoded = MIME::QuotedPrint->encode_qp($decoded);
  my $decoded = MIME::QuotedPrint->decode_qp($encoded);

=head1 Class Methods

=head2 encode_qp

C<static method encode_qp : string ($string : string, $eol : string = undef, $binmode : int = 0);>

Returns an Quoted-Printable encoded version of the string $string.

The second argument $eol is the line-ending sequence to use.  It is
optional and defaults to C<\n>.

Every occurrence of C<\n> is replaced
with this string, and it is also used for additional "soft line
breaks" to ensure that no line end up longer than 76 characters.

Pass it as C<\015\012> to produce data suitable for external consumption.
The string C<\r\n> produces the same result on many platforms, but not
all.

The third argument $binmode will select binary mode if passed as a
TRUE value.  In binary mode C<\n> will be encoded in the same way as
any other non-printable character.

This ensures that a decoder will
end up with exactly the same string whatever line ending sequence it
uses.

An $eol of "" (the empty string) is special.  In this case, no "soft
line breaks" are introduced and binary mode is effectively enabled so
that any C<\n> in the original data is encoded as well.

Exceptions:

$string must be defined. Otherwise an exception is thrown.

=head2 decode_qp
  
C<static method decode_qp : string ($string : string);>

Returns the plain text version of the Quoted-Printable string $string.

The lines of the result are C<\n> terminated, even if
the $string argument contains C<\r\n> terminated lines.

Exceptions:

$string must be defined. Otherwise an exception is thrown.

=head1 Distribution Containing This Class

L<SPVM::MIME::Base64>

=head1 Other Modules in This Distribution

=over 2

=item * L<SPVM::MIME::QuotedPrint>

=back

=head1 See Also

=over 2

=item * L<MIME::QuotedPrint> - SPVM::MIME::QuotedPrint is a MIME::QuotedPrint porting to SPVM

=back

=head1 Author

Yuki Kimoto (kimoto.yuki@gmail.com)

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

