#!perl 
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'PDF::Cairo' ) || print "Bail out!\n";
    use_ok( 'PDF::Cairo::Box' ) || print "Bail out!\n";
    use_ok( 'PDF::Cairo::Font' ) || print "Bail out!\n";
    use_ok( 'PDF::Cairo::Layout' ) || print "Bail out!\n";
}

diag( "Testing PDF::Cairo $PDF::Cairo::VERSION, Perl $], $^X" );

ok(defined $PDF::Cairo::Util::paper{b1}, 'papers.txt loaded successfully');
ok(defined $PDF::Cairo::rgb{dimgray}, 'rgb.txt loaded successfully');

my $pdf = PDF::Cairo->new(
	paper => 'a4',
	file => '00-load.pdf',
);
isa_ok($pdf, 'PDF::Cairo');
isa_ok($pdf->{context}, 'Cairo::Context');
my $surface = $pdf->{context}->get_target;
isa_ok($surface, 'Cairo::PdfSurface');

my $font = $pdf->loadfont('Times-BoldItalic');
isa_ok($font, 'PDF::Cairo::Font');
isa_ok($font->{face}, 'Cairo::FtFontFace');
ok($font->{type} eq 'freetype', 'FreeType font lookup succeeded');
diag("Font: ", join(",", $font->{_source}->{file}, $font->{_source}->{index}));

my $image = $pdf->loadimage('data/v04image002.png');
isa_ok($image, 'Cairo::ImageSurface');
ok($image->get_width == 930 && $image->get_height == 1200,
	'PNG loaded successfully');

diag("Pango layout initialization takes a while...");
my $layout = PDF::Cairo::Layout->new($pdf);
isa_ok($layout, 'PDF::Cairo::Layout');
isa_ok($layout->{_layout}, 'Pango::Layout');

done_testing();
