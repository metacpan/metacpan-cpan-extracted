#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('PDF::Make');
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Parser');
    use_ok('PDF::Make::Reader');
    use_ok('PDF::Make::Attachment');
    use_ok('PDF::Make::Color');
}

my $SIMPLE_PDF = q{%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj
xref
0 4
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
trailer
<< /Size 4 /Root 1 0 R >>
startxref
190
%%EOF
};

subtest 'Page getter dimensions are exact' => sub {
    my $doc = PDF::Make::Document->new;
    my $page = $doc->add_page(321.5, 654.25);

    isa_ok($page, 'PDF::Make::Page');
    is($page->width, 321.5, 'width getter returns custom width');
    is($page->height, 654.25, 'height getter returns custom height');
};

subtest 'Reader auto-parses parser' => sub {
    my $parser = PDF::Make::Parser->from_bytes($SIMPLE_PDF, repair => 1);
    my $reader = PDF::Make::Reader->new($parser);

    isa_ok($reader, 'PDF::Make::Reader');
    is($reader->page_count, 1, 'reader initializes from unparsed parser');

    my $doc = $parser->document;
    isa_ok($doc, 'PDF::Make::Document', 'parser document available after reader auto-parse');
};

subtest 'Reader validates constructor arguments' => sub {
    eval { PDF::Make::Reader->new('not a parser') };
    like($@, qr/argument must be a PDF::Make::Parser/, 'reader rejects non-parser argument');
};

subtest 'Attachment validation errors are explicit' => sub {
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);

    eval {
        PDF::Make::Attachment->attach($doc, data => 'payload');
    };
    like($@, qr/'name' is required/, 'attachment requires name');

    eval {
        PDF::Make::Attachment->attach($doc, name => 'missing.bin');
    };
    like($@, qr/'path' or 'data' is required/, 'attachment requires path or data');
};

subtest 'Color hex parser rejects invalid input' => sub {
    eval { PDF::Make::Color->hex_to_rgb('not-a-color') };
    like($@, qr/invalid hex color/i, 'invalid hex color throws');
};

subtest 'Parser from_file reports bad path' => sub {
    eval { PDF::Make::Parser->from_file('t/fixtures/does-not-exist.pdf') };
    like($@, qr/cannot open/, 'from_file reports missing path');
};

subtest 'Document to_file reports bad destination' => sub {
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);

    my $base = tempdir(CLEANUP => 1);
    my $bad_path = File::Spec->catfile($base, 'missing-dir', 'out.pdf');

    eval { $doc->to_file($bad_path) };
    like($@, qr/cannot open/, 'to_file reports bad destination path');
};

subtest 'Version API stays aligned with Perl version' => sub {
    my $c_version = PDF::Make::version();
    is($c_version, $PDF::Make::VERSION, 'XS version matches Perl version');
    like($c_version, qr/^\d+\.\d+$/, 'version string format is stable');
};

done_testing;
