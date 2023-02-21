#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::HTML;

my $str;

$str = String::Tagged::HTML->new
   ->append_tagged( "red", _span_style_color => "red" )
   ->append( " " )
   ->append_tagged( "big blue", _span_style_color => "blue", "_span_style_font-size" => "large" );

is( $str->as_html,
   qq(<span style="color: red;">red</span> <span style="color: blue; font-size: large;">big blue</span>),
   'generated HTML with <span style=...> tags' );

done_testing;
