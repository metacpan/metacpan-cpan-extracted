#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use String::Tagged::HTML;

my $str = String::Tagged::HTML->new( "Simple string" );

is( $str->str, "Simple string", '->str accessor' );

is( $str->as_html, "Simple string", '->as_html unwrapped' );

is( $str->as_html( "p" ), "<p>Simple string</p>", '->as_html <p> wrapped' );

$str = String::Tagged::HTML->new( "1 < 2 & 4 > 3" );

is( $str->as_html, "1 &lt; 2 &amp; 4 &gt; 3", '->as_html with escapes' );

$str = String::Tagged::HTML->new( "10 > 5<br/>" );
$str->apply_tag( 6, 5, raw => 1 );

is( $str->as_html, "10 &gt; 5<br/>", '->as_html with raw' );

$str = String::Tagged::HTML->new_raw( "Hello<br/>" );

is( $str->as_html, "Hello<br/>", '->new_raw constructs raw' );
