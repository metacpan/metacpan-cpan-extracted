#!/usr/bin/perl
# Feature: Header/Footer render context helpers
# Description: Uses the $ctx helper passed to add_page_header / add_page_footer
#              callbacks to build a rich header (title + divider + page counter)
#              and a footer (timestamp + link) without touching the raw canvas.
# Output: corpus/feature_examples/02_layout/header_footer_ctx.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/header_footer_ctx',
);

$pdf->add_page_header(
    h  => 40,
    cb => sub {
        my (undef, undef, %args) = @_;
        my $ctx = $args{ctx};
        $ctx->text(
            text  => 'PDF::Make Quarterly',
            align => 'left',
            font  => { size => 12, bold => 1, colour => '#1a1a2e' },
        );
        $ctx->page_num(
            format => 'Page {num} of {total}',
            align  => 'right',
            font   => { size => 9, colour => '#555' },
        );
        $ctx->line(
            x1 => $ctx->left  + 20, y1 => $ctx->bottom + 4,
            x2 => $ctx->right - 20, y2 => $ctx->bottom + 4,
            colour => '#999',
        );
    },
);

$pdf->add_page_footer(
    h  => 36,
    cb => sub {
        my (undef, undef, %args) = @_;
        my $ctx = $args{ctx};
        $ctx->line(
            x1 => $ctx->left  + 20, y1 => $ctx->top - 4,
            x2 => $ctx->right - 20, y2 => $ctx->top - 4,
            colour => '#ccc',
            type   => 'dashed',
        );
        $ctx->text(
            text  => 'Confidential - Internal Use Only',
            align => 'left',
            font  => { size => 8, italic => 1, colour => '#666' },
        );
        $ctx->text(
            text  => 'lnation.org',
            align => 'right',
            font  => { size => 8, colour => '#2563eb' },
        );
        # Hyperlink sitting over the right-aligned label
        $ctx->link(
            rect => [$ctx->right - 80, $ctx->bottom + 4,
                     $ctx->right - 20, $ctx->top    - 6],
            url  => 'https://lnation.org',
        );
    },
);

for my $n (1 .. 3) {
    $pdf->add_page(page_size => 'Letter', padding => 48)
        ->add_h1(text => "Chapter $n")
        ->add_text(text => 'Headers and footers built with ctx helpers render consistently across pages.')
        ->add_text(text => 'The page number helper substitutes {num} and {total} without per-page bookkeeping.');
}

$pdf->save();
print "Created corpus/feature_examples/02_layout/header_footer_ctx.pdf\n";
