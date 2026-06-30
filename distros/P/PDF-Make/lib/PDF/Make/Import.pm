package PDF::Make::Import;

use strict;
use warnings;

our $VERSION = '0.05';

use PDF::Make ();

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Import - Import pages and indirect objects from a parsed PDF

=head1 SYNOPSIS

    use PDF::Make::Parser;
    use PDF::Make::Reader;
    use PDF::Make::Document;
    use PDF::Make::Import;

    my $parser = PDF::Make::Parser->from_file('source.pdf', repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    my $doc    = PDF::Make::Document->new;

    my $importer = PDF::Make::Import->new($reader, $doc);

    # Append every page of the source into the destination document
    my $n = $importer->import_all_pages;

    # Or import individual pages:
    $importer->import_page(0);
    $importer->import_page(2);

=head1 DESCRIPTION

Copies pages (and their transitive object graph — content streams, fonts,
XObjects, ExtGState, Properties) from a parsed source PDF into a
destination C<PDF::Make::Document> that is still open for writing.

Name ids are re-interned in the destination arena, indirect references
are renumbered, and streams are deep-copied with their encoded bytes
preserved.  A remap table shared across all imports from the same
source ensures that shared resources (e.g. a font used by multiple
pages) are written once into the destination.

For the high-level C<< $builder->append_pdf($file) >> API, see
L<PDF::Make::Builder/append_pdf>.

=head1 METHODS

=head2 new($reader, $doc)

Create an import context.  C<$reader> is a L<PDF::Make::Reader>;
C<$doc> is the destination L<PDF::Make::Document>.

=head2 import_page($index)

Append the source page at 0-based C<$index> to the destination.
Returns 1 on success, 0 on failure.

=head2 import_all_pages

Append every source page in order.  Returns the number of pages
actually appended (may be less than the source page count on first
failure).

=head2 import_object($src_num)

Import the indirect object at C<$src_num> (and its transitive closure)
into the destination and return the new destination object number.
Repeated calls with the same C<$src_num> return the cached destination
number.

=head1 SCOPE

The importer currently handles: page dimensions, rotation, content
streams, and C</Resources> of type C</Font>, C</XObject>, C</ExtGState>,
C</Properties>.  Annotations, C</ColorSpace>, C</Pattern>, and
C</Shading> resource entries are not yet imported.  Encrypted source
PDFs must be authenticated on the reader before import.

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Reader>, L<PDF::Make::Document>

=cut
