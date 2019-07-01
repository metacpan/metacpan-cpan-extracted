#!perl 
use 5.016;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Cairo' ) || BAIL_OUT("No Cairo!");
    use_ok( 'Pango' ) || BAIL_OUT("No Pango!");
    use_ok( 'Font::FreeType' ) || BAIL_OUT("No Font::FreeType!");
}
BEGIN {
    # need this to debug CPAN test failures
    diag ( "\nLibrary versions linked against: " );
    diag ( "  cairo: " . Cairo->lib_version_string );
    diag ( "  pango: " . join(".", Pango->GET_VERSION_INFO) );
    diag ( "  freetype: " . Font::FreeType->new->version() );
	BAIL_OUT("libcairo version must be >= 1.10.0")
		unless Cairo->lib_version >= Cairo->LIB_VERSION_ENCODE(1,10,0);
	foreach my $mod ("", "::Box", "::Font", "::Layout", "::Util") {
		use_ok("PDF::Cairo$mod") || BAIL_OUT("can't load PDF::Cairo$mod");
	}
}

diag( "Testing PDF::Cairo $PDF::Cairo::VERSION, Perl $], $^X" );

ok(defined $PDF::Cairo::Util::paper{b1}, 'loading papers.txt');
ok(defined $PDF::Cairo::rgb{dimgray}, 'loading rgb.txt');

my $pdf = PDF::Cairo->new(
	paper => 'a4',
	file => '00-load.pdf',
);
isa_ok($pdf, 'PDF::Cairo');
isa_ok($pdf->{context}, 'Cairo::Context');
my $surface = $pdf->{context}->get_target;
isa_ok($surface, 'Cairo::PdfSurface');

my $font = $pdf->loadfont("data/Karla-Regular.ttf");
isa_ok($font, 'PDF::Cairo::Font');
isa_ok($font->{face}, 'Cairo::FtFontFace');
ok($font->{type} eq 'freetype', 'FreeType font lookup');
diag("Font: ", join(",", $font->{_source}->{file}, $font->{_source}->{index}));

my $image = $pdf->loadimage('data/v04image002.png');
isa_ok($image, 'Cairo::ImageSurface');
ok($image->width == 930 && $image->height == 1200,
	'loading PNG');

my $svg = $pdf->loadsvg('data/treasure-map.svg');
isa_ok($svg, 'PDF::Cairo');
isa_ok($svg->{context}, 'Cairo::Context');
isa_ok($svg->{context}->get_target, 'Cairo::RecordingSurface');
ok($svg->width == 512 && $svg->height == 512,
	'loading SVG into recording surface');

diag("Pango layout initialization takes a while...");
my $layout = PDF::Cairo::Layout->new($pdf);
isa_ok($layout, 'PDF::Cairo::Layout');
isa_ok($layout->{_layout}, 'Pango::Layout');

done_testing();
