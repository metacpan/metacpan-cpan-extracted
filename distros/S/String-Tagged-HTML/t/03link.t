#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use String::Tagged::HTML;

my $str;

$str = String::Tagged::HTML->new( "click here" );
$str->apply_tag( 6, 4, a => { href => "link" } );

is( $str->as_html, qq(click <a href="link">here</a>), 'unformatted link' );

$str = String::Tagged::HTML->new( "click here" );
$str->apply_tag( 6, 4, a => { href => q(<things> and 'quotes") } );

is( $str->as_html, qq(click <a href="&lt;things&gt; and &#39;quotes&quot;">here</a>), 'link with escaped entities' );
