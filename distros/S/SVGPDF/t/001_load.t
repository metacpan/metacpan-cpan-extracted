#! perl

use Test::More tests => 19;

BEGIN {
    # Load the elements first.
    use_ok("SVGPDF::Circle");
    use_ok("SVGPDF::CSS");
    use_ok("SVGPDF::Defs");
    use_ok("SVGPDF::Element");
    use_ok("SVGPDF::Ellipse");
    use_ok("SVGPDF::G");
    use_ok("SVGPDF::Image");
    use_ok("SVGPDF::Line");
    use_ok("SVGPDF::Parser");
    use_ok("SVGPDF::Path");
    use_ok("SVGPDF::Polygon");
    use_ok("SVGPDF::Polyline");
    use_ok("SVGPDF::Rect");
    use_ok("SVGPDF::Style");
    use_ok("SVGPDF::Svg");
    use_ok("SVGPDF::Text");
    use_ok("SVGPDF::Tspan");
    use_ok("SVGPDF::Use");

    # Master
    use_ok("SVGPDF");
}

diag( "Testing SVGPDF $SVGPDF::VERSION, Perl $], $^X" );

my @pdfapi = ( 'PDF::API2' => 2.043 ); # default
if ( my $a = $ENV{SVGPDF_API} ) {
    if ( $a =~ /PDF::Builder/ ) {
	@pdfapi = ( 'PDF::Builder' => 3.025 );
    }
    elsif ( $a =~ /PDF::API2/ ) {
    }
    else {
	@pdfapi = ( $a => 0 );
    }
}

diag( "Using $pdfapi[0] version $pdfapi[1]" );
