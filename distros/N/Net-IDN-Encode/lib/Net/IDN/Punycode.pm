package Net::IDN::Punycode;

use 5.006;

use strict;
use utf8;
use warnings;

use Exporter;

our $VERSION    = "2.600";
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( 'all'  => [ qw(encode_punycode decode_punycode) ], );
Exporter::export_ok_tags(keys %EXPORT_TAGS);
our $_NO_XS;

eval {
  die if $_NO_XS;
  require XSLoader;
  XSLoader::load('Net::IDN::Punycode');
};

if (!defined(&encode_punycode)) {
  require Net::IDN::Punycode::PP;
  Net::IDN::Punycode::PP->import(qw(:all));
}

1;
__END__

=head1 NAME

Net::IDN::Punycode - A Bootstring encoding of Unicode for IDNA (S<RFC 3492>)

=head1 SYNOPSIS

  use Net::IDN::Punycode qw(:all);
  $punycode = encode_punycode($unicode);
  $unicode  = decode_punycode($punycode);

=head1 DESCRIPTION

This module implements the Punycode encoding, and only the Punycode encoding.

This module does not implement any other steps required for converting
internationalized domain names (IDNs) to and from ASCII. In particular, it does
not do any string preparation as specified by I<Nameprep>/I<IDNA2008>/I<PRECIS>
and does not add nor remove the ACE prefix (C<xn-->). Thus, use
L<Net::IDN::Encode> if you want to convert domain names.

Punycode is an instance of a more general algorithm called Bootstring, which
allows strings composed from a small set of "basic" code points to uniquely
represent any string of code points drawn from a larger set. Punycode is
Bootstring with particular parameter values appropriate for IDNA.

=head1 WARNING

You may be tempted to use this module directly and add/remove the ACE prefix
(C<xn-->) in your code for performance reasons. Usually, this is not a good
idea.  If you convert domain labels (or other strings) without proper
preparation, you may end up with an ASCII encoding that is not interoperable or
even poses security issues due to spoofing.

Even if you think that your domain names are valid and already mapped to the
correct form, this may not be true. For example, some environments might
automatically convert your perfectly valid domain names to a different but
equivalent Unicode normalization form (e.g., NFD instead of NFC), which already
breaks IDNA.

=head1 FUNCTIONS

No functions are exported by default. You can use the tag C<:all>
or import them individually.

The following functions are available:

=over

=item encode_punycode($input)

Encodes C<$input> with Punycode and returns the result.
If C<$input> is undefined, the function raises an C<uninitialized>
warning and returns the empty string.

This function throws an exception on input it cannot encode. It
rejects malformed UTF-8 and a code point that is not a Unicode scalar
value. The latter covers a surrogate in U+D800 to U+DFFF and any
value above U+10FFFF. It also rejects input large enough to overflow
the Punycode counters.

The cost of encoding is quadratic in the length of the input. This is
a property of the algorithm as published in S<RFC 3492>. The function
does not limit the length of its input, so callers that accept
untrusted input should apply their own limit before encoding.
L<Net::IDN::UTS46> and L<Net::IDN::Encode> reject a label that is too
long for DNS before encoding it.

=item decode_punycode($input)

Decodes C<$input> with Punycode and returns the result.
If C<$input> is undefined, the function raises an C<uninitialized>
warning and returns the empty string.

This function throws an exception on input it cannot decode. It
rejects a character outside the basic set, an invalid or truncated
digit sequence, and a decoded code point that is not a Unicode scalar
value. It also rejects input large enough to overflow the Punycode
counters.

=back

=head1 AUTHORS

Tatsuhiko Miyagawa (versions 0.01 to 0.02)

Claus FE<auml>rber (versions 1.000 and higher)

Currently maintained by Robert Rothenberg <perl@rhizomnic.com> and Paul Johnson <paul@pjcj.net>.

=head1 LICENSE

Copyright 2002-2004 Tatsuhiko Miyagawa

Copyright 2007-2018 Claus FE<auml>rber

Parts copyright 2026 Robert Rothenberg <perl@rhizomnic.com> and Paul Johnson <paul@pjcj.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

S<RFC 3492> (L<http://www.ietf.org/rfc/rfc3492.txt>),
L<IETF::ACE>, L<Convert::RACE>

=cut
