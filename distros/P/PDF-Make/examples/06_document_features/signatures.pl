#!/usr/bin/perl
# Feature: Digital Signatures
# Description: Demonstrates signing a PDF with a PKCS#12 certificate, and
#              embedding a *real* visible signature widget drawn via the
#              PDF::Make::Builder::SignatureAppearance helper.
#              Requires corpus/fixtures/test_cert.p12 (password: testpass).
# Output: corpus/feature_examples/06_document_features/signatures.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $p12 = 'corpus/fixtures/test_cert.p12';

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/signatures',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Digitally Signed Document')
    ->add_text(text => 'This document has been digitally signed.')
    ->add_text(text => 'The signature can be verified in Adobe Reader or similar.')
    ->add_text(text => 'Look at the bottom-right of this page for the visible signature widget.');

if (-f $p12) {
    require PDF::Make::Signature;
    my $identity = eval {
        PDF::Make::Signature->load_identity(file => $p12, password => 'testpass')
    };
    if ($identity) {
        my $subject = $identity->subject // 'PDF::Make Test Signer';

        my @t = (localtime)[5, 4, 3, 2, 1, 0];
        my $date = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
            $t[0] + 1900, $t[1] + 1, @t[2, 3, 4, 5]);

        # Letter page = 612×792 pt.  Place a 220×90 signature widget near
        # the bottom-right (48pt inset).  Rect is [llx lly urx ury].
        my @rect = (612 - 48 - 220, 48, 612 - 48, 48 + 90);

        # Option C — custom appearance drawn with the SignatureAppearance
        # helper.  The callback receives a canvas-like object whose origin
        # is the bottom-left of the widget rectangle.
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
                $sa->text(
                    text => 'Digitally signed by',
                    size => 8, colour => '#555',
                    x => 6, y => $sa->top - 12,
                );
                $sa->text(
                    text => $subject,
                    size => 11, bold => 1, colour => '#1a1a2e',
                    x => 6, y => $sa->top - 26,
                );
                $sa->line(
                    x1 => 6, y1 => $sa->top - 32,
                    x2 => $sa->right - 6, y2 => $sa->top - 32,
                    colour => '#bbb',
                );
                $sa->text(
                    text => "Date:   $date",
                    size => 9, x => 6, y => $sa->top - 48,
                );
                $sa->text(
                    text => 'Reason: Demonstration',
                    size => 9, x => 6, y => $sa->top - 62,
                );
                $sa->text(
                    text => 'Location: PDF::Make feature examples',
                    size => 9, x => 6, y => $sa->top - 76,
                );
            },
        );
    } else {
        $pdf->add_text(text => "Certificate load failed: $@");
    }
} else {
    $pdf->add_text(text => '')
        ->add_text(text => "Skipped: $p12 not found. Run the test suite to generate it.");
}

eval { $pdf->save() };
if ($@) {
    my $err = $@;
    # The TSA HTTP call happens inside save().  If the TSA is unreachable,
    # fall back to signing without a timestamp so the example still produces
    # a valid (but not RFC 3161-timestamped) PDF.
    if ($err =~ /TSA/i) {
        warn "TSA unavailable: $err\nFalling back to signing without timestamp.\n";
        my @rect = (612 - 48 - 220, 48, 612 - 48, 48 + 90);
        $pdf->sign(
            pkcs12   => $p12,
            password => 'testpass',
            reason   => 'Demonstration of PDF::Make digital signing',
            location => 'PDF::Make feature examples',
            contact  => 'noreply@example.com',
            name     => $pdf->get_meta('Title') // 'PDF::Make Test Signer',
            visible  => 1,
            page     => 1,
            rect     => \@rect,
        );
        $pdf->save();
    } else {
        die $err;
    }
}
print "Created corpus/feature_examples/06_document_features/signatures.pdf\n";
