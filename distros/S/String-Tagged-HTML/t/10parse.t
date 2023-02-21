#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::HTML;

defined eval { require HTML::TreeBuilder; 1 } or
   plan skip_all => "HTML::TreeBuilder is not available";

# Simple tags
{
   my $str = String::Tagged::HTML->parse_html( "<b>Bold</b> and <i>Italic</i>" );

   is( $str->str, "Bold and Italic", 'Plaintext from HTML' );
   is( $str->get_tags_at( index $str, "Bold" ), { b => {} }, 'b tag' );
   is( $str->get_tags_at( index $str, "Italic" ), { i => {} }, 'i tag' );
}

# Tags with values
{
   my $str = String::Tagged::HTML->parse_html( "<span class=\"red\">Red</span>" );

   is( $str->str, "Red", 'Plaintext from HTML' );
   is( $str->get_tags_at( 0 ), { span => { class => "red" } }, 'span tag' );
}

done_testing;
