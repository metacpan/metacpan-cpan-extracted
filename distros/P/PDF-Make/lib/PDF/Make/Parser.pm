package PDF::Make::Parser;

use strict;
use warnings;

our $VERSION = '0.05';

# Load the XS code from PDF::Make
use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Parser - Parse existing PDF files

=head1 SYNOPSIS

    use PDF::Make::Parser;

    # Parse from bytes
    my $parser = PDF::Make::Parser->from_bytes($pdf_bytes);
    my $doc = $parser->document;

    # Parse from file
    my $parser = PDF::Make::Parser->from_file('document.pdf');
    my $doc = $parser->document;

    # Enable repair mode for broken PDFs
    my $parser = PDF::Make::Parser->from_file('broken.pdf', repair => 1);

    # Access parsed information
    print "Root object: ", $parser->root_num, " ", $parser->root_gen, " R\n";
    print "Xref size: ", $parser->xref_size, "\n";

    # Resolve an indirect reference
    my $obj_kind = $parser->resolve($num, $gen);

=head1 DESCRIPTION

C<PDF::Make::Parser> parses PDF files into a L<PDF::Make::Document>
structure. It supports classic xref tables, xref streams, hybrid files,
and incremental updates. An optional repair mode can reconstruct the
xref from a damaged file.

=head1 METHODS

=head2 from_bytes($bytes, %opts)

Create a parser from raw PDF bytes. Options:

=over 4

=item repair => 1

Enable repair mode to reconstruct xref from damaged files.

=back

=head2 from_file($path, %opts)

Create a parser from a file path. Same options as C<from_bytes>.

=head2 parse()

Run the parser. Called automatically by C<document()> and C<resolve()>
if needed. Returns C<$self>.

=head2 document()

Returns the parsed L<PDF::Make::Document>.

=head2 set_repair($enable)

Enable or disable repair mode before parsing.

=head2 root_num(), root_gen()

Return the object number and generation of the document root.

=head2 xref_size()

Return the number of entries in the cross-reference table.

=head2 resolve($num, $gen)

Resolve an indirect reference by object number and generation.
Auto-parses if needed.

=head2 errmsg(), erroffset()

Return error information if parsing failed.

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Document>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
