#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged::Terminal;
use Convert::Color;

# ->new_from_formatting
{
   # 100% red is index 9
   my $st = String::Tagged::Terminal->new_from_formatting(
      String::Tagged->new_tagged( "red", fg => Convert::Color->new( 'rgb:1,0,0' ) )
   );

   is( $st->get_tag_at( 0, "fgindex" ), 9, '$st has fgindex tag' );

   # monospace is altfont=1
   $st = String::Tagged::Terminal->new_from_formatting(
      String::Tagged->new_tagged( "mono", monospace => 1 )
   );

   is( $st->get_tag_at( 0, "altfont" ), 1, '$st has altfont tag' );
}

# ->as_formatting
{
   # 100% green is index 10
   my $st = String::Tagged::Terminal->new_tagged( "green", fgindex => 10 )
      ->as_formatting;

   is( uc $st->get_tag_at( 0, "fg" )->hex, "00FF00", '$st has fg tag' );

   # altfont=1 is monospace
   $st = String::Tagged::Terminal->new_tagged( "fixed", altfont => 1 )
      ->as_formatting;

   ok( $st->get_tag_at( 0, "monospace" ), '$st has monospace tag' );
}

done_testing;
