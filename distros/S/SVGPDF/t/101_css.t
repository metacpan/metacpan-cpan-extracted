#! perl

use Test::More tests => 7;
use SVGPDF::CSS;

my $css = SVGPDF::CSS->new;

$css->read_string( join("", <DATA>) );
is_deeply( $css->css,
	   {  '.f0' => { 'font-size'   => 10,
			 'font-family' => 'sans' },
	      'foo' => { color => 'blue' },
	      '*'   => $css->base,
	   },
	   "data" );

is( $css->find("color"), "black", "color" );

my $ctx = $css->ctx;

is_deeply( $ctx,
	   $css->base,
	   "find" );

my $ret = $css->push( { element => "foo", foo => "bar", class => "f0" } );

is_deeply( $css->css,
	   {  '.f0' => { 'font-size' => 10,
			 'font-family' => 'sans' },
	      '*'   => $css->base,
	      'foo' => { color => 'blue' },
	      '_'   => $ret,
	   },
	   "push" );

is( $css->find("color"), "blue", "color" );

$css->pop;

is_deeply( $css->css,
	   {  '.f0' => { 'font-size' => 10,
			 'font-family' => 'sans' },
	      '*'   => $css->base,
	      'foo' => { color => 'blue' },
	      '_'   => {}
	   },
	   "pop" );

is( $css->find("color"), "black", "color" );

__DATA__
.f0 { font: sans 10px }
foo { color: blue }
