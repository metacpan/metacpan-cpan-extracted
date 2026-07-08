package PDF::Make::Redaction;

use strict;
use warnings;

our $VERSION = '0.06';

use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Redaction - Mark and apply content redactions

=head1 SYNOPSIS

    use PDF::Make::Document;
    use PDF::Make::Canvas;
    use PDF::Make::Page qw(:fonts);
    use PDF::Make::Redaction;

    my $doc = PDF::Make::Document->new;
    $doc->title('Sensitive Report');
    $doc->author('Internal');
    my $page = $doc->add_page(612, 792);
    $page->add_std14_font('F1', HELVETICA);

    my $c = PDF::Make::Canvas->new;
    $c->BT->Tf('F1', 12)->Td(72, 700)->Tj('SSN: 123-45-6789')->ET;
    $page->set_content($c->to_bytes);

    # Mark areas for redaction
    PDF::Make::Redaction->mark($page,
        rect          => [100, 695, 280, 712],
        overlay_color => [0, 0, 0],
        overlay_text  => 'REDACTED',
    );

    # Or use individual coordinates
    PDF::Make::Redaction->mark($page,
        x0 => 100, y0 => 650, x1 => 280, y1 => 670,
    );

    # Check count
    my $n = PDF::Make::Redaction->count($page);  # 2

    # Apply redactions (burns overlays into content)
    PDF::Make::Redaction->apply_page($page);   # single page
    PDF::Make::Redaction->apply_doc($doc);      # all pages

    # Remove metadata (author, title, etc.)
    PDF::Make::Redaction->sanitize($doc);

    $doc->to_file('redacted.pdf');

=head1 DESCRIPTION

C<PDF::Make::Redaction> provides a two-step redaction workflow following PDF
specification conventions:

=over 4

=item 1. B<Mark> - Define rectangular areas to be redacted, with optional
overlay text and color.

=item 2. B<Apply> - Burn the redaction overlays into the content stream,
permanently removing the underlying content.

=back

A separate C<sanitize> step removes document-level metadata (title, author,
subject, etc.) from the Info dictionary.

=head1 CLASS METHODS

All methods are class methods called on C<PDF::Make::Redaction>.

=head2 mark($page, %args)

    PDF::Make::Redaction->mark($page,
        rect             => [x0, y0, x1, y1],  # or use x0/y0/x1/y1
        overlay_color    => [0, 0, 0],          # RGB, default black
        overlay_text     => 'REDACTED',         # optional text overlay
        overlay_font_size => 10,                # default 10pt
    );

Mark a rectangular area on C<$page> for redaction.

=over 4

=item C<rect> - ArrayRef of [x0, y0, x1, y1] in PDF coordinates

=item C<x0, y0, x1, y1> - Alternative: specify corners individually

=item C<overlay_color> - RGB color array for the redaction box (default [0,0,0])

=item C<overlay_text> - Text to display over the redacted area

=item C<overlay_font_size> - Font size for overlay text (default 10)

=back

=head2 count($page)

    my $n = PDF::Make::Redaction->count($page);

Returns the number of redaction marks on the given page.

=head2 apply_page($page)

    PDF::Make::Redaction->apply_page($page);

Apply all redaction marks on a single page, burning overlays into the
content stream. Croaks on failure.

=head2 apply_doc($doc)

    PDF::Make::Redaction->apply_doc($doc);

Apply all redaction marks across every page in the document. Croaks on
failure.

=head2 sanitize($doc)

    PDF::Make::Redaction->sanitize($doc);

Remove all metadata from the document's Info dictionary (title, author,
subject, keywords, creator, producer). This is typically called after
applying redactions to ensure no sensitive metadata remains. Croaks on
failure.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Page>, L<PDF::Make::Builder>

=cut
