#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use PDF::Builder;

my $pdf = PDF::Builder->new();

# Just standard core fonts for these tests (14), so those on Linux and on
# Windows should get the same results. In theory, could still do Windows
# fonts on Linux, as PDF::Builder supplies the font metrics files.

foreach my $font (
	qw(Courier Courier-Oblique Courier-Bold Courier-BoldOblique
           Helvetica Helvetica-Oblique Helvetica-Bold Helvetica-BoldOblique
           Times-Roman Times-Italic Times-Bold Times-BoldItalic
	   Symbol ZapfDingbats
          )) {  # hard-coded, later will test list of names
    lives_ok(sub { $pdf->corefont($font) }, "Load font $font");
}

ok($pdf->is_standard_font('Helvetica'),
   q{Helvetica is a standard font});

ok(!$pdf->is_standard_font('Comic Sans'),
   q{Comic Sans is not a standard font});

require PDF::Builder::Resource::Font::CoreFont;
my @names = PDF::Builder::Resource::Font::CoreFont->names();
is(scalar(@names), 14,
   q{names() returns 14 elements in array context});
@names = PDF::Builder::Resource::Font::CoreFont->names(1);
is(scalar(@names), 29,
   q{names(true) returns 29 elements in array context});

my $arrayref = PDF::Builder::Resource::Font::CoreFont->names();
is(ref($arrayref), 'ARRAY',
   q{names() returns an array reference in scalar context});
is(scalar(@$arrayref), 14,
   q{The array reference contains 14 elements});
$arrayref = PDF::Builder::Resource::Font::CoreFont->names(1);
is(ref($arrayref), 'ARRAY',
   q{names(1) returns an array reference in scalar context});
is(scalar(@$arrayref), 29,
   q{The array reference contains 29 elements});

@names = $pdf->standard_fonts();
is(scalar(@names), 14,
   q{$pdf->standard_fonts() returns an array with 14 elements});
foreach my $name (@names) {
    ok(PDF::Builder::Resource::Font::CoreFont->is_standard($name),
       qq{$name is a core font});
}
@names = $pdf->standard_fonts(1);
is(scalar(@names), 29,
   q{$pdf->standard_fonts(true) returns an array with 29 elements});
foreach my $name (@names) {
    ok(PDF::Builder::Resource::Font::CoreFont->is_standard($name, 1),
       qq{$name is a core font});
}
 
done_testing();

1;
