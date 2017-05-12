#!/usr/bin/perl -w

# Formal testing for PPI

# This test script only tests that the tree compiles

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 13;
use PPI       ();
use PPI::HTML ();

my $trivial_perl = 'my $foo = "bad";';
my $trivial_html = <<'END_HTML';
<span class="keyword">my</span> <span class="symbol">$foo</span> <span class="operator">=</span> <span class="double">&quot;bad&quot;</span><span class="structure">;</span>
END_HTML

sub new_ok {
	my $class  = shift;
	my $object = $class->new( @_ );
	isa_ok( $object, $class );
	$object;
}





#####################################################################
# Basic Empiric Testing

# Trivial Document to test some basics
{
	my $HTML1    = new_ok( 'PPI::HTML' );
	my $HTML2    = new_ok( 'PPI::HTML' );
	my $Document = new_ok( 'PPI::Document', \$trivial_perl );
	is( $HTML1->html( $Document ) . "\n", $trivial_html,
		'Trivial document matches expected HTML' );
	is_deeply( $HTML1, $HTML2, 'PPI::HTML object remains unchanged' );
	is( $HTML1->html( \$trivial_perl ) . "\n", $trivial_html,
		'Trivial document works with direct source reference' );
}




# Custom CSS
{
	my $CSS  = new_ok( 'CSS::Tiny' );
	my $HTML = new_ok( 'PPI::HTML', css => $CSS );
	isa_ok( $HTML->css, 'CSS::Tiny' );
}





# Line numbers and newlines
{
	my $HTML = new_ok( 'PPI::HTML', line_numbers => 1 );
	is( $HTML->html( \"this();\nthat();\n" ) . "\n", <<'END_HTML', 'Trivial document matches expected HTML' );
<span class="line_number">1: </span><span class="word">this</span><span class="structure">();</span><br>
<span class="line_number">2: </span><span class="word">that</span><span class="structure">();</span><br>
<span class="line_number">3: </span>
END_HTML
}





# Page wrap, and manually specify colors
{
	my $HTML = new_ok( 'PPI::HTML',
		page         => 1,
		line_numbers => 1,
		colors => {
			line_number => '#CCCCCC',
			number      => '#990000',
			},
		);
	is( $HTML->html( \"my \$foo = 1;\n" ), <<'END_HTML', 'Page wrapped, manually coloured page matches expected' );
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="robots" content="noarchive">
<style type="text/css">
<!--
.number {
	color: #990000;
}
.line_number {
	color: #CCCCCC;
}
-->
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000"><pre><span class="line_number">1: </span>my $foo = <span class="number">1</span>;<br>
<span class="line_number">2: </span></pre></body>
</html>
END_HTML
}

exit();
