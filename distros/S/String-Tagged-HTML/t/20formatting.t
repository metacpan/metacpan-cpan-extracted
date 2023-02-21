#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::HTML;
use constant HAVE_CONVERT_COLOR => defined eval { require Convert::Color; 1 };

# ->new_from_formatting
{
   # Simple boolean tags
   foreach (
      [ bold      => "strong" ],
      [ italic    => "em" ],
      [ under     => "u" ],
      [ strike    => "strike" ],
      [ monospace => "tt" ],
   ) {
      my ( $tag, $elem ) = @$_;

      my $st = String::Tagged->new
         ->append_tagged( "text", $tag => 1 );

      my $sth = String::Tagged::HTML->new_from_formatting( $st );
      is( $sth->as_html, "<$elem>text</$elem>",
         "$tag tag renders as <$elem>" );
   }

   # Sub/superscript are values of the 'sizepos' tag
   foreach ( [ sub => "sub" ], [ super => "sup" ] ) {
      my ( $val, $elem ) = @$_;

      my $st = String::Tagged->new
         ->append_tagged( "text", sizepos => $val );

      my $sth = String::Tagged::HTML->new_from_formatting( $st );
      is( $sth->as_html, "<$elem>text</$elem>",
         "sizepos=$val renders as <$elem>" );
   }

   if(HAVE_CONVERT_COLOR) {
      my $st = String::Tagged->new
         ->append_tagged( "red", fg => Convert::Color->new( "vga:red" ) )
         ->append_tagged( "black-on-green", bg => Convert::Color->new( "vga:green" ) );

      my $sth = String::Tagged::HTML->new_from_formatting( $st );
      is( $sth->as_html, qq(<span style="color: #ff0000;">red</span><span style="background-color: #00ff00;">black-on-green</span>),
         'fg and bg rendered as span style' );
   }
}

# Linefeed conversion
{
   is( String::Tagged::HTML->new_from_formatting( String::Tagged->new( "foo\nbar" ) )
         ->as_html,
      "foo<br/>\nbar",
      'Linefeeds are converted to <br/> tags' );
}

done_testing;
