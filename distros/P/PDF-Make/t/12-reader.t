#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('PDF::Make::Parser');
    use_ok('PDF::Make::Reader');
}

#==============================================================================
# Test PDFs
#==============================================================================

# Simple 1-page PDF
my $SIMPLE_PDF = q{%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792]
   /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT /F1 24 Tf 72 720 Td (Hello) Tj ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000264 00000 n 
0000000357 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
431
%%EOF
};

# Multi-page PDF with inheritance
my $MULTI_PDF = q{%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R 4 0 R 5 0 R] /Count 3 /MediaBox [0 0 595 842] >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R >>
endobj
4 0 obj
<< /Type /Page /Parent 2 0 R /Rotate 90 >>
endobj
5 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 300] >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000150 00000 n 
0000000196 00000 n 
0000000255 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
321
%%EOF
};

#==============================================================================
# Basic reader tests
#==============================================================================

subtest 'Reader creation' => sub {
    plan tests => 4;

    my $parser = PDF::Make::Parser->from_bytes($SIMPLE_PDF, repair => 1);
    ok($parser, 'parser created');

    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    ok($reader, 'reader created');
    isa_ok($reader, 'PDF::Make::Reader');
    is($reader->page_count, 1, 'page count is 1');
};

subtest 'Page access' => sub {
    plan tests => 5;

    my $parser = PDF::Make::Parser->from_bytes($SIMPLE_PDF, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    my $page = $reader->page(0);
    ok($page, 'page 0 retrieved');
    isa_ok($page, 'PDF::Make::Reader::Page');

    # Test media box
    my @box = $page->media_box;
    is(scalar @box, 4, 'media_box returns 4 values');
    is_deeply(\@box, [0, 0, 612, 792], 'media_box values correct');

    # Test rotation (should be 0)
    is($page->rotation, 0, 'rotation is 0');
};

subtest 'Page content' => sub {
    plan tests => 3;

    my $parser = PDF::Make::Parser->from_bytes($SIMPLE_PDF, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    my $page = $reader->page(0);

    my $content = $page->content_bytes;
    ok(defined $content, 'content_bytes defined');
    ok(length($content) > 0, 'content has length');
    like($content, qr/BT.*Tf.*ET/s, 'content contains text operators');
};

#==============================================================================
# Multi-page and inheritance tests
#==============================================================================

subtest 'Multi-page document' => sub {
    plan tests => 8;

    my $parser = PDF::Make::Parser->from_bytes($MULTI_PDF, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    is($reader->page_count, 3, 'page count is 3');

    # Page 0: inherits MediaBox from parent
    my $page0 = $reader->page(0);
    my @box0 = $page0->media_box;
    is_deeply(\@box0, [0, 0, 595, 842], 'page 0 inherits MediaBox');
    is($page0->rotation, 0, 'page 0 rotation is 0');

    # Page 1: inherits MediaBox, has Rotate
    my $page1 = $reader->page(1);
    my @box1 = $page1->media_box;
    is_deeply(\@box1, [0, 0, 595, 842], 'page 1 inherits MediaBox');
    is($page1->rotation, 90, 'page 1 rotation is 90');

    # Page 2: overrides MediaBox
    my $page2 = $reader->page(2);
    my @box2 = $page2->media_box;
    is_deeply(\@box2, [0, 0, 400, 300], 'page 2 overrides MediaBox');
    is($page2->rotation, 0, 'page 2 rotation is 0');

    # CropBox should fall back to MediaBox
    my @crop = $page0->crop_box;
    is_deeply(\@crop, [0, 0, 595, 842], 'crop_box falls back to media_box');
};

#==============================================================================
# Error handling
#==============================================================================

subtest 'Error handling' => sub {
    plan tests => 2;

    my $parser = PDF::Make::Parser->from_bytes($SIMPLE_PDF, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    eval { $reader->page(999) };
    like($@, qr/out of range/i, 'out of range page throws');

    is($reader->errmsg, '', 'errmsg is empty after success');
};

#==============================================================================
# File-based parsing
#==============================================================================

subtest 'Parse from file' => sub {
    plan tests => 3;

    # Write test PDF to temp file
    my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.pdf');
    print $fh $SIMPLE_PDF;
    close $fh;

    my $parser = PDF::Make::Parser->from_file($filename, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    ok($reader, 'reader from file created');
    is($reader->page_count, 1, 'page count correct');

    my $page = $reader->page(0);
    my @box = $page->media_box;
    is_deeply(\@box, [0, 0, 612, 792], 'media_box from file correct');
};

done_testing;
