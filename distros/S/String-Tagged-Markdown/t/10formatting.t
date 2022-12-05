#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

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
}

# ->as_formatting
{
   my $st = String::Tagged::Markdown->parse_markdown( "`monospace`" )
      ->as_formatting;

   ok( $st->get_tag_at( 0, "monospace" ), '$st has monospace tag' );
}

done_testing;
