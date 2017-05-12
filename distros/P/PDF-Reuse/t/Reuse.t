#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Deep;

BEGIN {
        use_ok('PDF::Reuse') or BAIL_OUT "Can't load PDF::Reuse";
}

### NOTE: Any changes in the module code which result in a change to the contents of test.pdf
### will require a corresponding change in the expected contents as listed below the __DATA__
### tag at the end of this test file.

my $built_in_fonts = {
    'TR'  => 'Times-Roman',
    'TB'  => 'Times-Bold',
    'TI'  => 'Times-Italic',
    'TBI' => 'Times-BoldItalic',
    'C'   => 'Courier',
    'CB'  => 'Courier-Bold',
    'CO'  => 'Courier-Oblique',
    'CBO' => 'Courier-BoldOblique',
    'H'   => 'Helvetica',
    'HB'  => 'Helvetica-Bold',
    'HO'  => 'Helvetica-Oblique',
    'HBO' => 'Helvetica-BoldOblique',
    'S'   => 'Symbol',
    'Z'   => 'ZapfDingbats',
};

prFile('./test.pdf');

my $f_flag = 1 if -e './test.pdf';
is ($f_flag, 1, "PDF file created successfully");

# Test findFont
$PDF::Reuse::font = 'H';
my ($foINTNAME, $foEXTNAME, $foREFOBJ) = PDF::Reuse::findFont();
subtest 'PDF::Reuse::findFont successfully locates fonts'    => sub{
    plan tests  => 3;
    is ($foINTNAME, 'Ft1', "Internal font name is correct");
    is ($foEXTNAME, 'Helvetica', "External font name is correct");
    is ($foREFOBJ, '4', "PDF reference object for this font is correct");
};

# Test prText
prText(250, 650, 'Hello World !');
is ($PDF::Reuse::stream, '0 0 0 rg
 0 g
f

BT /Ft1 12 Tf 250 650 Td (Hello World !) Tj ET
', "PDF Stream is created correctly");

# Test prFont
is (prFont("Times-Roman"),'Ft2', 'prFont returns the correct internal font name');



prEnd();

# Test newly created PDF file
open (my $pdf, "<", "test.pdf") or BAIL_OUT "Can't open test.pdf: $!";
binmode $pdf;
my @pdf_got = <$pdf>;
close $pdf;

binmode main::DATA, ':encoding(UTF-8)';
my @pdf_expected = <main::DATA>;
# Line 29 contains two MD% hashes which are time-based and change with every new
# PDF file created, so we will ignore it while testing the resulting file.
$pdf_expected[31] = ignore();
close main::DATA;

cmp_deeply(\@pdf_got, \@pdf_expected, "PDF file successfully written");

__DATA__
%PDF-1.4
%âãÏÓ
4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica/Encoding/WinAnsiEncoding>>endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Times-Roman/Encoding/WinAnsiEncoding>>endobj
6 0 obj<</ProcSet[/PDF/Text]/Font << /Ft1 4 0 R/Ft2 5 0 R >>>>endobj
7 0 obj<</Length 64>>stream
0 0 0 rg
 0 g
f

BT /Ft1 12 Tf 250 650 Td (Hello World !) Tj ET

endstream
endobj
3 0 obj<</Type/Page/Parent 2 0 R/Contents 7 0 R/MediaBox [0 0 595 842]/Resources 6 0 R>>endobj
2 0 obj<</Type/Pages/Kids [3 0 R ]/Count 1 >>endobj
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
xref
0 8
0000000000 65535 f 
0000000515 00000 n 
0000000463 00000 n 
0000000368 00000 n 
0000000015 00000 n 
0000000101 00000 n 
0000000189 00000 n 
0000000258 00000 n 
trailer
<<
/Size 8
/Root 1 0 R
/ID [<d29e8d34f9ec01330a2b6e4e8a6640f7><d29e8d34f9ec01330a2b6e4e8a6640f7>]
>>
startxref
558
%%EOF
