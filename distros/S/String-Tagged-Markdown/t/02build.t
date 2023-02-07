#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Markdown;

# build tags
{
   my $str;

   $str = String::Tagged::Markdown->new( "Simple string" );

   is( $str->build_markdown, "Simple string",
      '->build_markdown plain' );

   # italic
   $str = String::Tagged::Markdown->new( "String with " )
      ->append_tagged( "italic", italic => 1 );

   is( $str->build_markdown, "String with *italic*",
      '->build_markdown italic' );

   # bold
   $str = String::Tagged::Markdown->new( "String with " )
      ->append_tagged( "bold", bold => 1 );

   is( $str->build_markdown, "String with **bold**",
      '->build_markdown bold' );

   # strike
   $str = String::Tagged::Markdown->new( "String with " )
      ->append_tagged( "strike", strike => 1 );

   is( $str->build_markdown, "String with ~~strike~~",
      '->build_markdown strike' );

   # fixed
   $str = String::Tagged::Markdown->new( "String with " )
      ->append_tagged( "fixed", fixed => 1 );

   is( $str->build_markdown, "String with `fixed`",
      '->build_markdown fixed' );
}

# fixed-width does not need to escape other markers
{
   my $str = String::Tagged::Markdown->new( "This is " )
      ->append_tagged( "fixed_here", fixed => 1 );

   is( $str->build_markdown, "This is `fixed_here`" );
}

# fixed-width can use multiple markers to escape the meaning inside
{
   my $str = String::Tagged::Markdown->new
      ->append_tagged( "this has `backticks`", fixed => 1 );

   is( $str->build_markdown, "`` this has `backticks` ``" );
}

# marker text gets escaped
{
   my $str = String::Tagged::Markdown->new( "This is *not italic*" );

   is( $str->build_markdown, "This is \\*not italic\\*",
      'Marker chars get escaped' );
}

# links
{
   my $str;

   $str = String::Tagged::Markdown->new( "String with " )
      ->append_tagged( "link", link => "http://target" );

   is( $str->build_markdown, "String with [link](http://target)",
      '->build_markdown link' );

   $str = String::Tagged::Markdown->new( "Link with fixed" );
   $str->apply_tag( 10, 5, fixed => 1 );
   $str->apply_tag( 10, 5, link => "target" );

   is( $str->build_markdown, "Link with [`fixed`](target)",
      '->build_markdown link' );
}

done_testing;
