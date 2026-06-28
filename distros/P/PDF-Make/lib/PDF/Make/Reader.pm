package PDF::Make::Reader;

use strict;
use warnings;

our $VERSION = '0.02';

# Load the XS code from PDF::Make
use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Reader - Read page information from parsed PDFs

=head1 SYNOPSIS

    use PDF::Make::Parser;
    use PDF::Make::Reader;

    # Parse the PDF first
    my $parser = PDF::Make::Parser->from_file('document.pdf', repair => 1);
    $parser->parse;

    # Create reader to access page content
    my $reader = PDF::Make::Reader->new($parser);
    
    # Get page count
    my $count = $reader->page_count;
    print "Document has $count pages\n";
    
    # Access individual pages
    for my $i (0 .. $count - 1) {
        my $page = $reader->page($i);
        
        # Get page dimensions
        my @media_box = $page->media_box;  # (llx, lly, urx, ury)
        my @crop_box  = $page->crop_box;   # Falls back to media_box
        my $rotation  = $page->rotation;   # 0, 90, 180, or 270
        
        print "Page $i: ", ($media_box[2] - $media_box[0]), "x",
              ($media_box[3] - $media_box[1]), " rotation=$rotation\n";
        
        # Get raw content stream bytes (decoded)
        my $content = $page->content_bytes;
        print "Content length: ", length($content), " bytes\n";
    }

=head1 DESCRIPTION

C<PDF::Make::Reader> provides access to page information from parsed
PDF documents. It handles page tree flattening, inheritable attribute
resolution, and content stream extraction.

=head1 METHODS

=head2 new($parser)

Create a new reader from a L<PDF::Make::Parser>. The parser must have
already been parsed (parse() called or via document() method).

The reader initializes by flattening the page tree and caching page
references.

=head2 page_count()

Returns the number of pages in the document.

=head2 page($index)

Returns a L<PDF::Make::Reader::Page> object for the page at the given
0-based index. Throws an exception if the index is out of range.

=head2 errmsg()

Returns the last error message, or empty string if no error.

=head1 SEE ALSO

L<PDF::Make::Reader::Page>, L<PDF::Make::Parser>

=cut

package PDF::Make::Reader::Page;

1;

__END__

=head1 NAME

PDF::Make::Reader::Page - A single page from a PDF document

=head1 SYNOPSIS

    my $page = $reader->page(0);
    
    my @media_box = $page->media_box;  # (0, 0, 612, 792)
    my @crop_box  = $page->crop_box;   # defaults to media_box
    my $rotation  = $page->rotation;   # 0, 90, 180, 270
    my $content   = $page->content_bytes;

=head1 DESCRIPTION

Represents a single page from a PDF document. Provides access to
page attributes (with inheritance from parent Pages nodes) and
decoded content stream bytes.

=head1 METHODS

=head2 media_box()

Returns a list of four numbers (llx, lly, urx, ury) representing the
page media box in default user space units (points, 1/72 inch).

The media box defines the boundaries of the physical medium.

=head2 crop_box()

Returns a list of four numbers (llx, lly, urx, ury) representing the
page crop box. If no crop box is specified, returns the media box.

The crop box defines the visible region of the page.

=head2 rotation()

Returns the page rotation in degrees: 0, 90, 180, or 270.
Invalid rotation values are normalized to 0.

=head2 content_bytes()

Returns the decoded content stream bytes as a single binary string.
If the page has no content stream, returns an empty string.
If the page has an array of content streams, they are concatenated
with whitespace separators.

=head1 SEE ALSO

L<PDF::Make::Reader>

=cut
