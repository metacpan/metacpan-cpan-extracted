package PDF::Make;

use strict;
use warnings;

our $VERSION = '0.04';

use DynaLoader;
our @ISA = ('DynaLoader');

# Make our C symbols globally visible so downstream XS modules in
# Semantic can #include "pdfmake.h" and link against us.
sub dl_load_flags { 0x01 }

bootstrap PDF::Make $VERSION;

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make - PDF generation, parsing, and editing

=head1 SYNOPSIS

    # High-level Builder API (recommended)
    use PDF::Make::Builder;

    PDF::Make::Builder->new(file_name => 'report.pdf')
        ->add_page(page_size => 'A4')
        ->title('Quarterly Report')
        ->author('Jane Smith')
        ->add_h1(text => 'Q4 Results')
        ->add_text(text => 'Revenue increased 15% year-over-year.')
        ->add_line(x => 72, ex => 523)
        ->add_image(image => 'chart.jpg', w => 400)
        ->add_outline('Q4 Results', page => 0)
        ->save;

    # Low-level XS API (full control)
    use PDF::Make::Document;
    use PDF::Make::Canvas;
    use PDF::Make::Page qw(:fonts);

    my $doc  = PDF::Make::Document->new;
    my $page = $doc->add_page(612, 792);
    $page->add_std14_font('F1', HELVETICA);

    my $c = PDF::Make::Canvas->new;
    $c->BT->Tf('F1', 24)->Td(72, 700)->Tj('Hello, World!')->ET;
    $page->set_content($c->to_bytes);

    $doc->to_file('hello.pdf');

=head1 DESCRIPTION

C<PDF::Make> is a from-scratch PDF implementation for the Semantic ecosystem.
The engine is a pure-C library (C<libpdfmake>) with zero runtime dependencies
-- no zlib, OpenSSL, libjpeg, or ICU. All compression, encryption, font
handling, and image decoding is implemented in C.

The distribution provides two API layers:

=over 4

=item B<PDF::Make::Builder> - High-level, chainable, Object::Proto-based API
for common document creation tasks. Handles coordinate translation, page
management, word-wrap, and font metrics automatically.

=item B<PDF::Make::Document> / B<PDF::Make::Canvas> - Low-level XS API that
maps directly to PDF specification concepts. Gives full control over content
streams, object graphs, and page structure.

=back

=head1 MODULES

=head2 Core

=over 4

=item L<PDF::Make::Document> - Create and serialise PDF documents

=item L<PDF::Make::Page> - Page objects with font and content management

=item L<PDF::Make::Canvas> - Content stream builder (all PDF operators)

=item L<PDF::Make::Writer> - Low-level PDF serialiser

=item L<PDF::Make::Arena> - Memory arena for PDF object graphs

=item L<PDF::Make::Obj> - PDF primitive wrappers (int, string, array, dict)

=back

=head2 Parsing and Reading

=over 4

=item L<PDF::Make::Parser> - Parse existing PDF files

=item L<PDF::Make::Reader> - Read page information from parsed PDFs

=item L<PDF::Make::Extract> - Extract text, annotations, forms, and tables from PDF pages

=back

=head2 Fonts and Images

=over 4

=item L<PDF::Make::Font> - Standard 14 and TrueType font handling

=item L<PDF::Make::Image> - JPEG and PNG image embedding

=back

=head2 Interactive Features

=over 4

=item L<PDF::Make::Action> - Link actions (URI, GoTo, Named, JavaScript)

=item L<PDF::Make::Form> - AcroForm interactive forms

=item L<PDF::Make::Field> - Form field types (text, checkbox, radio, combo)

=back

=head2 Document Features

=over 4

=item L<PDF::Make::Layer> - Optional Content Groups (layers/OCG)

=item L<PDF::Make::Attachment> - Embedded file attachments

=item L<PDF::Make::Structure> - Tagged PDF and accessibility (StructTree)

=item L<PDF::Make::Color> - Color spaces (sRGB, Separation, CMYK)

=item L<PDF::Make::Watermark> - Text and image watermarks, stamps

=item L<PDF::Make::Redaction> - Content redaction and metadata sanitisation

=back

=head2 Security

=over 4

=item L<PDF::Make::Crypt> - Encryption (RC4, AES-128, AES-256)

=item L<PDF::Make::Signature> - Digital signatures (PKCS#12, X.509)

=back

=head2 Output

=over 4

=item L<PDF::Make::Linearization> - Fast Web View (linearised PDF)

=back

=head2 Builder (High-Level API)

=over 4

=item L<PDF::Make::Builder> - Chainable document builder

=item L<PDF::Make::Builder::Font> - Font registry and metrics

=item L<PDF::Make::Builder::Page> - Page state and layout

=item L<PDF::Make::Builder::Text> - Word-wrapped text with alignment

=item L<PDF::Make::Builder::Image> - Image placement

=item L<PDF::Make::Builder::TOC> - Table of contents generation

=item L<PDF::Make::Builder::Shape::Line> - Line drawing

=item L<PDF::Make::Builder::Shape::Box> - Rectangle drawing

=item L<PDF::Make::Builder::Shape::Circle> - Circle drawing

=item L<PDF::Make::Builder::Shape::Ellipse> - Ellipse drawing

=item L<PDF::Make::Builder::Shape::Pie> - Pie/arc sector drawing

=back

=head1 FUNCTIONS

=head2 version()

    my $v = PDF::Make::version();

Returns the C<libpdfmake> version string.

=head1 DEPENDENCIES

=over 4

=item * L<Object::Proto> - Call-checker-optimised accessors for Builder classes.

=back

No other runtime dependencies.

=head1 SEE ALSO

L<PDF::Make::Builder> for the recommended high-level API.

L<Object::Proto>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
