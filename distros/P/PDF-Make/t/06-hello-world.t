#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;
use File::Spec;

use_ok('PDF::Make');

# Standard 14 font constants (match pdfmake_page.h)
use constant {
    FONT_HELVETICA             => 0,
    FONT_HELVETICA_BOLD        => 1,
    FONT_HELVETICA_OBLIQUE     => 2,
    FONT_HELVETICA_BOLDOBLIQUE => 3,
    FONT_TIMES_ROMAN           => 4,
    FONT_TIMES_BOLD            => 5,
    FONT_TIMES_ITALIC          => 6,
    FONT_TIMES_BOLDITALIC      => 7,
    FONT_COURIER               => 8,
    FONT_COURIER_BOLD          => 9,
    FONT_COURIER_OBLIQUE       => 10,
    FONT_COURIER_BOLDOBLIQUE   => 11,
    FONT_SYMBOL                => 12,
    FONT_ZAPFDINGBATS          => 13,
};

# Test basic document with page
my $doc = PDF::Make::Document->new();
isa_ok($doc, 'PDF::Make::Document', 'Document created');

# Add a page (letter size is default)
my $page = $doc->add_page();
isa_ok($page, 'PDF::Make::Page', 'Page created');

# Add font to page using standard 14
my $font_num = $page->add_std14_font('F1', FONT_HELVETICA);
ok($font_num > 0, 'Font added to page');

# Set content stream - "Hello, World!" at position (72, 720)
my $content = <<'CONTENT';
BT
/F1 24 Tf
72 720 Td
(Hello, World!) Tj
ET
CONTENT

$page->set_content($content);
pass('Content stream set');

# Write PDF to test fixtures area
my $corpus_dir = File::Spec->catdir('t', 'fixtures');
mkdir $corpus_dir unless -d $corpus_dir;
my $pdf_path = File::Spec->catfile($corpus_dir, 'hello_world.pdf');

# Use to_file to write directly
$doc->to_file($pdf_path);
pass('PDF written successfully');
ok(-f $pdf_path, 'PDF file exists');

# Verify PDF content
open my $fh, '<:raw', $pdf_path or die "Cannot read $pdf_path: $!";
my $pdf_content = do { local $/; <$fh> };
close $fh;

# Check PDF structure
like($pdf_content, qr/%PDF-[12]\.\d/, 'PDF has correct header');
like($pdf_content, qr{/Type /Catalog}, 'PDF has Catalog');
like($pdf_content, qr{/Type /Pages}, 'PDF has Pages');
like($pdf_content, qr{/Type /Page}, 'PDF has Page');

diag("Hello World PDF written to: $pdf_path");
