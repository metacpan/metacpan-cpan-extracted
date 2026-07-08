package PDF::Make::Writer;

use strict;
use warnings;

our $VERSION = '0.06';

# Load the XS code from PDF::Make
use PDF::Make ();

# XS bindings will provide:
#   new()         - create a new writer with internal buffer
#   write($obj)   - serialize an object, returns $self for chaining
#   to_bytes()    - return accumulated bytes and reset buffer
#   buf()         - accessor for internal buffer pointer (for advanced use)
#   len()         - accessor for current buffer length
#   DESTROY()     - free internal buffer

1;

__END__

=head1 NAME

PDF::Make::Writer - PDF object serializer

=head1 SYNOPSIS

    use PDF::Make::Writer;
    use PDF::Make::Arena;

    my $arena = PDF::Make::Arena->new;

    # Create some objects
    my $name = $arena->name('Type');
    my $dict = $arena->dict;
    $dict->set('Type', $arena->name('Catalog'));
    $dict->set('Pages', $arena->ref(2, 0));

    # Serialize them
    my $writer = PDF::Make::Writer->new;
    $writer->write($dict);
    my $bytes = $writer->to_bytes;
    # $bytes = "<</Type /Catalog/Pages 2 0 R>>"

    # Method chaining
    my $output = PDF::Make::Writer->new
        ->write($arena->int(42))
        ->write($arena->name('Test'))
        ->to_bytes;

=head1 DESCRIPTION

C<PDF::Make::Writer> serializes C<pdfmake_obj_t> object trees into
byte-exact PDF syntax per ISO 32000-1:2008 E<sect>7.3.

The serializer is deterministic and produces identical output for
identical input. It handles:

=over 4

=item * B<Scalars>: null, boolean, integer, real

=item * B<Strings>: literal (with escapes) and hexadecimal

=item * B<Names>: with E<sect>7.3.5 escape sequences

=item * B<Composites>: arrays, dictionaries, streams

=item * B<References>: indirect object references (N G R)

=back

=head1 METHODS

=head2 new

    my $writer = PDF::Make::Writer->new;

Create a new writer instance with an empty internal buffer.

=head2 write

    $writer->write($obj);

Serialize C<$obj> and append to the internal buffer. Returns C<$self>
for method chaining.

=head2 to_bytes

    my $bytes = $writer->to_bytes;

Return the accumulated serialized bytes as a string and reset the
internal buffer. After calling C<to_bytes>, the writer is ready for
reuse.

=head2 len

    my $length = $writer->len;

Return the current length of the internal buffer in bytes.

=head2 buf

    my $ptr = $writer->buf;

Return a pointer to the internal buffer data. For advanced use only.

=head1 NUMBER FORMATTING

Numbers are formatted locale-independently per E<sect>7.3.3:

=over 4

=item * Integers are printed without decimal point: C<42>, C<-123>

=item * Reals use minimal fractional digits: C<1.5>, C<0.25>

=item * Integer-valued reals print without decimal: C<42> not C<42.0>

=back

=head1 STRING ESCAPING

Literal strings (E<sect>7.3.4.2) escape:

    \n  newline
    \r  carriage return
    \t  tab
    \b  backspace
    \f  form feed
    \\  backslash
    \(  left parenthesis
    \)  right parenthesis

Hexadecimal strings emit uppercase: C<< <DEADBEEF> >>

=head1 NAME ESCAPING

Names (E<sect>7.3.5) escape bytes outside the regular set using C<#XX>:

=over 4

=item * NUL (0x00)

=item * Whitespace (space, tab, newline, carriage return, form feed)

=item * Delimiters: C<( ) < > [ ] { } / %>

=item * The number sign: C<#>

=item * Bytes outside 0x21-0x7E

=back

=head1 SEE ALSO

L<PDF::Make::Obj>, L<PDF::Make::Arena>, L<PDF::Make>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
