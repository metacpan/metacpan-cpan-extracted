#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Markdown;

# parse tags
{
   my $str;

   $str = String::Tagged::Markdown->parse_markdown( "Simple string" );

   is( $str->str, "Simple string", '->str on plain' );
   is( [ $str->tagnames ], [], 'plain has no tags' );

   # italic
   $str = String::Tagged::Markdown->parse_markdown( "String with *italic*" );

   is( $str->str, "String with italic", '->str on italic' );
   is( [ $str->tagnames ], [qw( italic )], 'italic has tag' );

   # bold
   $str = String::Tagged::Markdown->parse_markdown( "String with **bold**" );

   is( $str->str, "String with bold", '->str on bold' );
   is( [ $str->tagnames ], [qw( bold )], 'bold has tag' );

   # alternate italic/bold
   $str = String::Tagged::Markdown->parse_markdown( "String with _italic_" );

   is( $str->str, "String with italic", '->str on italic' );
   is( [ $str->tagnames ], [qw( italic )], 'italic has tag' );

   $str = String::Tagged::Markdown->parse_markdown( "String with __bold__" );

   is( $str->str, "String with bold", '->str on bold' );
   is( [ $str->tagnames ], [qw( bold )], 'bold has tag' );

   # strike
   $str = String::Tagged::Markdown->parse_markdown( "String with ~~strike~~" );

   is( $str->str, "String with strike", '->str on strike' );
   is( [ $str->tagnames ], [qw( strike )], 'strike has tag' );

   # fixed
   $str = String::Tagged::Markdown->parse_markdown( "String with `fixed`" );

   is( $str->str, "String with fixed", '->str on fixed' );
   is( [ $str->tagnames ], [qw( fixed )], 'fixed has tag' );
}

# escape disarms markers
{
   my $str = String::Tagged::Markdown->parse_markdown( "This is \\*not italic\\*" );

   is( $str->str, "This is *not italic*",
      'Escape disarms markers' );
   is( [ $str->tagnames ], [], 'Escaped has no tags' );
}

# fixed-width does not recurse on other patterns
{
   my $str = String::Tagged::Markdown->parse_markdown( "`code_with_underscores`" );

   is( $str->str, "code_with_underscores",
      'Fixed-width with inner unders' );
   is( [ $str->tagnames ], [qw( fixed )], 'Fixed-width does not emit italics' );
}

# fixed-width can use multiple markers to escape the meaning inside
{
   my $str = String::Tagged::Markdown->parse_markdown( "`` this has `backticks` ``" );

   is( $str->str, "this has `backticks`",
      'Doubled backticks disarm single ones inside' );
   is( [ $str->tagnames ], [qw( fixed )], 'Fixed-width does not emit italics' );
}

# links
{
   my $str;

   $str = String::Tagged::Markdown->parse_markdown( "String with [link](http://target) inside" );

   is( $str->str, "String with link inside", '->str on link' );
   is( [ $str->tagnames ], [qw( link )], 'link has tag' );
   is( $str->get_tag_at( 13, "link" ), "http://target", 'link target' );

   $str = String::Tagged::Markdown->parse_markdown( "Link with [`fixed`](target)" );
   is( $str->str, "Link with fixed", '->str on link' );
   is( $str->get_tags_at( 10 ), { link => "target", fixed => 1 },
      'Link text has link and fixed' );
}

# HTML entities
{
   my $str;

   $str = String::Tagged::Markdown->parse_markdown( "A dash &ndash; like this &amp; that" );

   # ndash = U+2013
   is( $str->str, "A dash \x{2013} like this & that", 'HTML entities decoded' );

   $str = String::Tagged::Markdown->parse_markdown( "But not in \`this &amp; place\`" );

   is( $str->str, "But not in this &amp; place", 'HTML entities not decoded in code span' );
}

done_testing;
