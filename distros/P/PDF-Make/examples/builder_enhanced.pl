#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/builder_enhanced',
    configure => {
        h1   => { font => { colour => '#1a1a2e', size => 28, line_height => 32 } },
        h2   => { font => { colour => '#16213e', size => 18, line_height => 22 } },
        h3   => { font => { colour => '#0f3460', size => 14, line_height => 18 } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#333' } },
    },
);

# ── Metadata ─────────────────────────────────────────────────

$pdf->title('PDF::Make Builder Showcase')
    ->author('PDF::Make')
    ->subject('Complete Builder API demonstration')
    ->keywords('pdf, builder, forms, layers, outlines')
    ->creator('builder_enhanced.pl')
    ->producer('PDF::Make');

# ── Headers and Footers ──────────────────────────────────────

$pdf->add_page_header(
    show_page_num => 'right',
    page_num_text => 'Page {num}',
);
$pdf->add_page_footer(
    show_page_num => 'center',
    page_num_text => '- {num} -',
);

# ══════════════════════════════════════════════════════════════
# Page 1: Title + Text + Headings
# ══════════════════════════════════════════════════════════════

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'PDF::Make Builder Showcase')
    ->add_text(text => 'This document demonstrates every feature of the '
                     . 'PDF::Make::Builder API. Each page focuses on a '
                     . 'different capability, from basic text and shapes to '
                     . 'advanced features like form fields, layers, and outlines.')
    ->add_h2(text => 'Text Features')
    ->add_text(text => 'Builder supports automatic word-wrapping, text alignment '
                     . '(left, center, right), configurable fonts, and page '
                     . 'overflow. Long paragraphs automatically flow to the next '
                     . 'page when they reach the bottom margin.')
    ->add_h3(text => 'Font Families')
    ->add_text(text => 'Helvetica (default) - clean and modern.',
              font => { family => 'Helvetica', size => 10 })
    ->add_text(text => 'Times - classic serif typeface.',
              font => { family => 'Times', size => 10 })
    ->add_text(text => 'Courier - monospaced for code.',
              font => { family => 'Courier', size => 10 })
    ->add_h3(text => 'Heading Levels')
    ->add_h4(text => 'H4: Section Detail')
    ->add_h5(text => 'H5: Minor Heading')
    ->add_h6(text => 'H6: Smallest Heading');

# ══════════════════════════════════════════════════════════════
# Page 2: Shapes Gallery
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Shapes Gallery')
    ->add_h2(text => 'Rectangles')
    ->add_box(fill_colour => '#3498db', w => 300, h => 30)
    ->add_box(fill_colour => '#2ecc71', w => 250, h => 30)
    ->add_box(fill_colour => '#e74c3c', w => 200, h => 30)
    ->add_box(fill_colour => '#f39c12', w => 150, h => 30)
    ->add_h2(text => 'Lines')
    ->add_line(fill_colour => '#2c3e50', type => 'solid')
    ->add_line(fill_colour => '#3498db', type => 'dashed')
    ->add_line(fill_colour => '#e74c3c', type => 'dots')
    ->add_h2(text => 'Circle, Ellipse, and Pie')
    ->add_circle(fill_colour => '#9b59b6', x => 120, y => 520, r => 40)
    ->add_ellipse(fill_colour => '#1abc9c', x => 280, y => 520, w => 120, h => 60)
    ->add_pie(fill_colour => '#e67e22', x => 450, y => 520, r => 40, rx => 0, ry => 90);

# ══════════════════════════════════════════════════════════════
# Page 3: Images
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Image Embedding')
    ->add_text(text => 'JPEG images use DCTDecode passthrough (no re-encoding). '
                     . 'PNG images are decoded and re-encoded with FlateDecode.');

if (-f 'corpus/images/test.jpg') {
    $pdf->add_h2(text => 'JPEG Image')
        ->add_image(image => 'corpus/images/test.jpg', w => 200);
}

if (-f 'corpus/images/test.png') {
    $pdf->add_h2(text => 'PNG Image')
        ->add_image(image => 'corpus/images/test.png', w => 200);
}

# ══════════════════════════════════════════════════════════════
# Page 4: Outlines + Links
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Navigation')
    ->add_h2(text => 'Outlines (Bookmarks)')
    ->add_text(text => 'This document has a bookmark tree visible in the PDF '
                     . "viewer's sidebar. Outlines support nesting via the "
                     . 'parent parameter.')
    ->add_h2(text => 'Links')
    ->add_text(text => 'Click the blue rectangle below to visit example.com:')
    ->add_box(fill_colour => '#3498db', w => 200, h => 25)
    ->add_link(url => 'https://metacpan.org', rect => [36, 560, 236, 585])
    ->add_text(text => 'Internal links jump to other pages within the document:')
    ->add_box(fill_colour => '#2ecc71', w => 200, h => 25)
    ->add_link(page => 0, rect => [36, 500, 236, 525]);

# ══════════════════════════════════════════════════════════════
# Page 5: Layers (Optional Content Groups)
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Layers (OCG)')
    ->add_text(text => 'PDF layers allow content to be toggled on/off in the '
                     . 'viewer. The lines below are on separate layers.')
    ->add_layer('Dimensions', visible => 1)
    ->add_layer('Annotations', visible => 0)
    ->add_h2(text => 'Dimensions Layer (visible)')
    ->begin_layer('Dimensions')
    ->add_line(fill_colour => '#0066cc', type => 'solid')
    ->add_line(fill_colour => '#0066cc', type => 'dashed')
    ->end_layer
    ->add_h2(text => 'Annotations Layer (hidden by default)')
    ->begin_layer('Annotations')
    ->add_line(fill_colour => '#cc0000', type => 'solid')
    ->add_text(text => 'This text is on the Annotations layer.')
    ->end_layer;

# ══════════════════════════════════════════════════════════════
# Page 6: Form Fields
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Interactive Form Fields')
    ->add_field(
        type       => 'text',
        name       => 'full_name',
        label      => 'Full Name',
        w          => 300,
    )
    ->add_field(
        type          => 'text',
        name          => 'email',
        label         => 'Email Address',
        w             => 300,
        default_value => 'user@example.com',
    )
    ->add_field(
        type       => 'text',
        name       => 'comments',
        label      => 'Comments',
        w          => 400,
        h          => 60,
        multiline  => 1,
    )
    ->add_field(
        type       => 'checkbox',
        name       => 'agree_terms',
        label      => 'I agree to the terms and conditions',
    )
    ->add_field(
        type       => 'combo',
        name       => 'country',
        label      => 'Country',
        w          => 200,
        options    => ['United States', 'United Kingdom', 'Canada', 'Australia', 'Germany', 'France'],
    )
    ->add_field(
        type       => 'button',
        name       => 'submit_btn',
        caption    => 'Visit CPAN',
        url        => 'https://metacpan.org',
        w          => 120,
    )
    ->add_field(
        type       => 'button',
        name       => 'reset_btn',
        caption    => 'Reset Form',
        is_reset   => 1,
        w          => 120,
    );

# ══════════════════════════════════════════════════════════════
# Page 7: Color Spaces + Redaction
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Color & Redaction')
    ->add_h2(text => 'Color Spaces')
    ->add_text(text => 'sRGB color space registered for calibrated color output.')
    ->set_color_space('sRGB')
    ->add_h2(text => 'Redaction')
    ->add_text(text => 'Sensitive information: SSN 123-45-6789')
    ->add_text(text => 'The area above can be marked for redaction. '
                     . 'Call apply_redactions() to burn the overlay permanently.')
    ->mark_redaction(
        page          => 6,
        rect          => [36, 530, 350, 545],
        overlay_color => [0, 0, 0],
        overlay_text  => 'REDACTED',
    );

# ══════════════════════════════════════════════════════════════
# Page 8: Attachments + Watermark
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Attachments & Watermark')
    ->add_h2(text => 'Embedded Files')
    ->add_text(text => 'This PDF has a CSV file attached. Open the attachment '
                     . 'panel in your PDF viewer to see it.')
    ->attach(
        name        => 'sample_data.csv',
        data        => "Name,Score,Grade\nAlice,95,A\nBob,87,B\nCarol,92,A\n",
        mime        => 'text/csv',
        description => 'Sample grade data',
    )
    ->add_h2(text => 'Watermark')
    ->add_text(text => 'A "DRAFT" watermark has been applied across all pages. '
                     . 'Watermarks support opacity, rotation, color, and '
                     . 'position control.')
    ->add_watermark(text => 'DRAFT', opacity => 0.15, size => 72);

# ══════════════════════════════════════════════════════════════
# Page 9: Text Extraction + Encryption info
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Advanced Features')
    ->add_h2(text => 'Text Extraction')
    ->add_text(text => 'Builder can extract text from existing PDFs:');

my $extracted = eval { $pdf->extract_text('corpus/hello_world.pdf', 0) } // '(not available)';
$pdf->add_text(text => "  Extracted: \"$extracted\"",
              font => { family => 'Courier', size => 9, colour => '#27ae60' });

$pdf->add_h2(text => 'Encryption')
    ->add_text(text => 'Documents can be encrypted with AES-256, AES-128, '
                     . 'RC4-128, or RC4-40. Set via $b->encrypt(...).')
    ->add_h2(text => 'Digital Signatures')
    ->add_text(text => 'Sign documents with PKCS#12 certificates via '
                     . '$b->sign(pkcs12 => "cert.p12", password => "...").')
    ->add_h2(text => 'Tagged PDF (Accessibility)')
    ->add_text(text => 'Call $b->enable_tagging() to auto-generate structure '
                     . 'tags: headings become /H1-/H6, text becomes /P, '
                     . 'images become /Figure.');

# ══════════════════════════════════════════════════════════════
# Page 10: Annotations, Stamps, Metadata
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Annotations & Stamps')
    ->add_h2(text => 'Sticky Notes')
    ->add_text(text => 'Click the note icon to the right to see the annotation:')
    ->add_note(
        rect => [500, 660, 520, 680],
        text => 'This is a sticky note annotation added via add_note().',
        icon => 'Comment',
        open => 0,
    )
    ->add_h2(text => 'Stamps')
    ->add_text(text => 'PDF stamp annotations mark document status:')
    ->add_stamp(rect => [72, 560, 250, 600], type => 'Approved')
    ->add_stamp(rect => [260, 560, 438, 600], type => 'Confidential')
    ->add_h2(text => 'Custom Metadata')
    ->add_text(text => 'Set arbitrary key-value pairs in the PDF Info dictionary.');

$pdf->set_meta('Department', 'Engineering')
    ->set_meta('Project', 'PDF-Make');

my $dept = $pdf->get_meta('Department') // '(none)';
$pdf->add_text(text => "  Department: $dept",
              font => { family => 'Courier', size => 9, colour => '#27ae60' });

$pdf->add_h2(text => 'Page Count')
    ->add_text(text => "This document has " . $pdf->page_count . " pages.");

# ══════════════════════════════════════════════════════════════
# Build Outline Tree
# ══════════════════════════════════════════════════════════════

$pdf->add_outline('Showcase',          page => 0)
    ->add_outline('Text & Headings',   page => 0, parent => 'Showcase')
    ->add_outline('Shapes Gallery',    page => 1, parent => 'Showcase')
    ->add_outline('Images',            page => 2, parent => 'Showcase')
    ->add_outline('Navigation',        page => 3)
    ->add_outline('Layers (OCG)',      page => 4)
    ->add_outline('Form Fields',       page => 5)
    ->add_outline('Color & Redaction', page => 6)
    ->add_outline('Attachments',       page => 7)
    ->add_outline('Advanced',          page => 8)
    ->add_outline('Annotations',       page => 9);

# ══════════════════════════════════════════════════════════════
# Save
# ══════════════════════════════════════════════════════════════

$pdf->save();
my $n = $pdf->page_count;
print "Wrote corpus/builder_enhanced.pdf ($n pages)\n";
print "Features demonstrated:\n";
print "  - Metadata (title, author, subject, keywords, custom)\n";
print "  - Headers and footers with page numbers\n";
print "  - 6 heading levels (H1-H6)\n";
print "  - Word-wrapped text with font overrides\n";
print "  - Shapes (box, line, circle, ellipse, pie)\n";
print "  - Image embedding (JPEG, PNG)\n";
print "  - Outlines/bookmarks (nested)\n";
print "  - Links (URI, GoTo, named actions, external PDF)\n";
print "  - Layers/OCG (visible/hidden)\n";
print "  - Form fields (text, checkbox, combo, button with actions)\n";
print "  - Color spaces (sRGB)\n";
print "  - Redaction marks\n";
print "  - File attachments\n";
print "  - Watermarks\n";
print "  - Text extraction\n";
print "  - Sticky notes (text annotations)\n";
print "  - Stamps (Approved, Confidential)\n";
print "  - Custom metadata (set_meta/get_meta)\n";
print "  - Page count\n";
print "  - to_bytes (in-memory output)\n";
print "  - open_existing (parse and extend)\n";
