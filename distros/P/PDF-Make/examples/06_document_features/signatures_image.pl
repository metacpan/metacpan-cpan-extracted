#!/usr/bin/perl
# Feature: Digital Signatures with an image-based appearance
# Description: Same flow as signatures.pl, but the visible widget
#              embeds a scanned "scribbled" signature PNG instead of a
#              text-only block.  If corpus/fixtures/scribble_signature.png
#              does not exist, a small synthetic scribble is generated
#              once so the example is self-contained.
# Output: corpus/feature_examples/06_document_features/signatures_image.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use Compress::Zlib qw(compress);
use PDF::Make::Builder;
use PDF::Make::Signature;  # for identity loading and signing API

make_path('corpus/feature_examples/06_document_features');
make_path('corpus/fixtures');

my $p12          = 'corpus/fixtures/test_cert.p12';
my $scribble_png = 'corpus/fixtures/scribble_signature.png';

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/signatures_image',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Image-Based Visible Signature')
    ->add_text(text => 'This document is digitally signed.')
    ->add_text(text => 'The visible widget on page 1 embeds a PNG of the signer\'s scribbled signature.');

my $identity = eval {
    PDF::Make::Signature->load_identity(file => $p12, password => 'testpass')
};

if ($identity) {
    my $subject = $identity->subject // 'PDF::Make Test Signer';

    my @t = (localtime)[5, 4, 3, 2, 1, 0];
    my $date = sprintf('%04d-%02d-%02d',
        $t[0] + 1900, $t[1] + 1, $t[2]);

    # 240x96pt widget near the bottom-right of a Letter page (612x792).
    my @rect = (612 - 48 - 240, 48, 612 - 48, 48 + 96);

    $pdf->sign(
        pkcs12        => $p12,
        password      => 'testpass',
        reason        => 'Demonstration of PDF::Make digital signing',
        location      => 'PDF::Make feature examples',
        contact       => 'noreply@example.com',
        name          => $subject,
        timestamp_url => 'http://timestamp.digicert.com',
        tsa_timeout   => 15,
        visible       => 1,
        page          => 1,
        rect          => \@rect,
        appearance    => sub {
            my ($sa) = @_;
            $sa->box(fill_colour => '#ffffff');
            $sa->box(fill_colour => 'transparent', width => 0.8);

            # Scribbled signature image — takes the top ~60% of the box.                
            my $img_h = $sa->h * 0.60;
            $sa->image(
                file => $scribble_png,
                x    => 6,
                y    => $sa->top - 6 - $img_h,
                w    => $sa->w - 12,
                h    => $img_h,
            );
            # Caption underneath.
            $sa->line(
                x1 => 6, x2 => $sa->right - 6,
                y1 => $sa->top - 6 - $img_h - 2,
                y2 => $sa->top - 6 - $img_h - 2,
                colour => '#bbb',
            );
            $sa->text(
                text => $subject,
                size => 9, bold => 1,
                x => 6, y => $sa->top - 6 - $img_h - 16,
            );
            $sa->text(
                text => "Signed $date",
                size => 8, colour => '#555',
                x => 6, y => $sa->top - 6 - $img_h - 28,
            );
        },
    );
} else {
    $pdf->add_text(text => "Certificate load failed: $@");
}

$pdf->save();

print "Created corpus/feature_examples/06_document_features/signatures_image.pdf\n";
