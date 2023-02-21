#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::HTML;

my $str;

$str = String::Tagged::HTML->new_tagged( "bold text", b => 1 );
is( $str->as_html, "<b>bold text</b>", 'bold' );

$str = String::Tagged::HTML->new_tagged( "italic text", i => 1 );
is( $str->as_html, "<i>italic text</i>", 'italic' );

$str = String::Tagged::HTML->new_tagged( "underline text", u => 1 );
is( $str->as_html, "<u>underline text</u>", 'underline' );

$str = String::Tagged::HTML->new_tagged( "small text", small => 1 );
is( $str->as_html, "<small>small text</small>", 'small' );

$str = String::Tagged::HTML->new_tagged( "bold and italic text", b => 1 );
$str->apply_tag( 9, 6, i => 1 );
is( $str->as_html, "<b>bold and <i>italic</i> text</b>", 'italic nested in bold' );

$str = String::Tagged::HTML->new( "bbb b+i iii" );
$str->apply_tag( 0, 7, b => 1 );
$str->apply_tag( 4, 7, i => 1 );
is( $str->as_html, "<b>bbb <i>b+i</i></b><i> iii</i>", 'bold/italic overlapped' );

$str = String::Tagged::HTML->new_tagged( "classy text", span => { class => "main" } );
is( $str->as_html, qq(<span class="main">classy text</span>), 'bold' );

$str = String::Tagged::HTML->new( "one and two" );
$str->apply_tag( 0, 3, code => 1 );
$str->apply_tag( 8, 3, code => 1 );
is( $str->as_html, "<code>one</code> and <code>two</code>" );

done_testing;
