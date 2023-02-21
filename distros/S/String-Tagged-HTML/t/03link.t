#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::HTML;

my $str;

$str = String::Tagged::HTML->new( "click here" );
$str->apply_tag( 6, 4, a => { href => "link" } );

is( $str->as_html, qq(click <a href="link">here</a>), 'unformatted link' );

$str = String::Tagged::HTML->new( "click here" );
$str->apply_tag( 6, 4, a => { href => q(<things> and 'quotes") } );

is( $str->as_html, qq(click <a href="&lt;things&gt; and &#39;quotes&quot;">here</a>), 'link with escaped entities' );

done_testing;
