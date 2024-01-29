#! perl

# Testing ".class element" selector.

use Test::More tests => 12;
use SVGPDF::CSS;

my $css = SVGPDF::CSS->new;

$css->read_string( join("", <DATA>) );
is_deeply( $css->css,
	   {  '.f0' => { 'font-size'   => 10,
			 'font-family' => 'sans',
			 ' foo' => { color => 'red' }
		       },
	      'foo' => { color => 'blue' },
	      '*'   => $css->base,
	   },
	   "[] data" );

is( $css->find("color"), "black", "[] black is the color" );

is_deeply( $css->ctx, $css->base, "[] find" );

$ret = $css->push( element => "foo" );
is( $css->find("color"), "blue", "[foo] blue is the color of foo" );
$css->pop;

is_deeply( $css->css,
	   {  '.f0' => { 'font-size'   => 10,
			 'font-family' => 'sans',
			 ' foo' => { color => 'red' }
		       },
	      'foo' => { color => 'blue' },
	      '*'   => $css->base,
	      '_'   => {},
	   },
	   "[] popped" );
#use DDumper; DDumper $css->css;exit;
is( $css->find("color"), "black", "[] color is black again" );

$ret = $css->push( class => "f0" );
is( $css->find("color"), "black", "[.fo] black is the color of f0" );
$ret = $css->push( element => "foo" );
is( $css->find("color"), "red", "[foo.f0] red is the color of foo.f0" );

is_deeply( $css->css,
	   {  '.f0' => { 'font-size' => 10,
			 'font-family' => 'sans',
			 ' foo' => { color => 'red' }
		       },
	      '*'   => $css->base,
	      'foo' => { color => 'blue' },
	      '_'   => $ret,
	   },
	   "[foo.f0] find" );

$css->pop;

is( $css->find("color"), "black", "[.f0] color if blue again" );

$css->pop;

is_deeply( $css->css,
	   {  '.f0' => { 'font-size' => 10,
			 'font-family' => 'sans',
			 ' foo' => { color => 'red' }
		       },
	      '*'   => $css->base,
	      'foo' => { color => 'blue' },
	      '_'   => {}
	   },
	   "[] pop" );

is( $css->find("color"), "black", "[] color is black again" );

__DATA__
.f0 { font: sans 10px }
foo { color: blue }
.f0 foo { color: red }
