#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use File::Spec;

BEGIN {
    use_ok('PDF::Make::Parser');
    use_ok('PDF::Make::Extract');
}

# Test with inline PDF
my $pdf = q{%PDF-1.4
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

my $parser = PDF::Make::Parser->from_bytes($pdf, repair => 1);
ok($parser, 'parser created');

my $text = PDF::Make::Extract->extract($parser, 0);
ok(defined $text, 'text extracted');
like($text, qr/Hello/, 'extracted "Hello"');

# Test with hello_world.pdf
my $hw_path = File::Spec->catfile('t', 'fixtures', 'hello_world.pdf');
my $hw_parser = PDF::Make::Parser->from_file($hw_path);
my $hw_text = PDF::Make::Extract->extract($hw_parser, 0);
ok(defined $hw_text, 'hello_world text extracted');
like($hw_text, qr/Hello/, 'contains Hello');
like($hw_text, qr/World/, 'contains World');

done_testing;
