#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Markdown;

# ->new_from_formatting
{
   my $st = String::Tagged::Markdown->new_from_formatting(
      String::Tagged->new
         ->append_tagged( "bold", bold => 1 )
         ->append( " " )
         ->append_tagged( "italic", italic => 1 )
         ->append( " " )
         ->append_tagged( "strike", strike => 1 )
         ->append( " " )
         ->append_tagged( "monospace", monospace => 1 )
   );

   is( $st->build_markdown, "**bold** *italic* ~~strike~~ `monospace`",
      '$st handles S:T:Formatting tags' );

   $st = String::Tagged::Markdown->new_from_formatting(
      String::Tagged->new
         ->append_tagged( "link", link => { uri => "scheme://target" } )
   );

   is( $st->build_markdown, "[link](scheme://target)",
      '$st handles S:T:Formatting link tag' );
}

# ->as_formatting
{
   my $st = String::Tagged::Markdown->parse_markdown( "`monospace`" )
      ->as_formatting;

   ok( $st->get_tag_at( 0, "monospace" ), '$st has monospace tag' );

   $st = String::Tagged::Markdown->parse_markdown( "[link](scheme://target)" )
      ->as_formatting;

   is( $st->get_tag_at( 0, "link" ), { uri => "scheme://target" },
      '$st has link tag' );
}

# custom convert_tags
{
   my $st = String::Tagged::Markdown->new_from_formatting(
      String::Tagged->new
         ->append_tagged( "text", a_tag => 1 ),
      convert_tags => {
         a_tag => "bold"
      }
   );

   is( $st->build_markdown, "**text**",
      '->new_from_formatting permits custom convert_tags' );

   my $st2 = $st->as_formatting(
      convert_tags => {
         bold => "a_tag"
      }
   );

   is( [ $st2->tagnames ], [qw( a_tag )],
      '->as_formatting permits custom convert_tags' );
}

done_testing;
