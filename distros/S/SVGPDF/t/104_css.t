#! perl

use Test::More tests => 2;
use SVGPDF::CSS;

my $css = SVGPDF::CSS->new;

$css->read_string( join("", grep { !/^#/ } <DATA>) );

is_deeply( $css->css,
	   {  '.f0' => { 'font-size'   => '24.0',
			 'font-family' => 'abc2svg',
			 ' text' => { fill => 'currentColor',
				      'white-space' => 'pre' },
		       },
	      '.f1' => { 'font-size'   => '12.0',
			 'font-family' => 'serif',
			 'font-weight' => 'bold',
		       },
	      tspan => { fill => 'currentColor',
			 'white-space' => 'pre' },
	      '*'   => $css->base,
	   },
	   "[] data" );

#use DDumper; warn( "Initial: ", DDumper $css->css );

$css->push(  color => "black",
	     'stroke-width' => ".7",
	     style => "background-color: white",
	     class => "f0 tune0" );

#warn "Outer:", DDumper $css->ctx;

$css->push( element => "text", class => "f1" );

#warn "text: ", DDumper $css->ctx;

$css->push( element => "tspan", class => "f0", style => "font-size:15.6px" );

#warn "tspan: ", DDumper $css->ctx;

is( $css->find("font-family"), "abc2svg", "class clash" );

=for later

$css->push( element => "tspan" ); $css->pop;

DDumper $css->ctx;

$css->pop;			# tspan

DDumper $css->ctx;

$css->push( element => "tspan" );

DDumper $css->ctx;

$css->pop;			# tspan

DDumper $css->ctx;

$css->pop;			# text

DDumper $css->ctx;

=cut

__DATA__
.f0{font:24.0px abc2svg.ttf}
.f0 text,tspan{fill:currentColor;white-space:pre}
.f1{font:bold 12.0px text,serif}
#[att1]{color:red}
#text[att2=red]{color:red}
#foo>bar{color:blue}
 
