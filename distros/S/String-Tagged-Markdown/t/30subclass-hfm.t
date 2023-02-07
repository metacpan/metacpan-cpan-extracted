#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Markdown::HFM;
use Convert::Color;

# parse HFM
{
   my $str;

   # Examples taken from hedgedoc "Help" page

   # superscript
   $str = String::Tagged::Markdown::HFM->parse_markdown( "19^th" );

   is( $str->str, "19th", '->str on superscript' );
   is( [ $str->tagnames ], [qw( superscript )], 'superscript has tag' );

   # subscript
   $str = String::Tagged::Markdown::HFM->parse_markdown( "H~2~O" );

   is( $str->str, "H2O", '->str on subscript' );
   is( [ $str->tagnames ], [qw( subscript )], 'subscript has tag' );

   # underline
   $str = String::Tagged::Markdown::HFM->parse_markdown( "++underline++" );

   is( $str->str, "underline", '->str on underline' );
   is( [ $str->tagnames ], [qw( underline )], 'underline has tag' );

   # highlight
   $str = String::Tagged::Markdown::HFM->parse_markdown( "==highlight==" );

   is( $str->str, "highlight", '->str on highlight' );
   is( [ $str->tagnames ], [qw( highlight )], 'highlight has tag' );

   # common codes also
   $str = String::Tagged::Markdown::HFM->parse_markdown( "**bold** *italic* ~~strike~~" );

   is( $str->str, "bold italic strike", '->str on common codes' );
   is( [ sort $str->tagnames ], [qw( bold italic strike )], 'common codes has tags' );
}

# build HFM
{
   my $str;

   # superscript
   $str = String::Tagged::Markdown::HFM->new( "String with " )
      ->append_tagged( "superscript", superscript => 1 );

   is( $str->build_markdown, "String with ^superscript^",
      'build superscript' );

   # subscript
   $str = String::Tagged::Markdown::HFM->new( "String with " )
      ->append_tagged( "subscript", subscript => 1 );

   is( $str->build_markdown, "String with ~subscript~",
      'build subscript' );

   # underline
   $str = String::Tagged::Markdown::HFM->new( "String with " )
      ->append_tagged( "underline", underline => 1 );

   is( $str->build_markdown, "String with ++underline++",
      'build underline' );

   # highlight
   $str = String::Tagged::Markdown::HFM->new( "String with " )
      ->append_tagged( "highlight", highlight => 1 );

   is( $str->build_markdown, "String with ==highlight==",
      'build highlight' );

   # common codes also
   $str = String::Tagged::Markdown::HFM->new( "String with " )
      ->append_tagged( "bold",   bold   => 1 )
      ->append( " " )
      ->append_tagged( "italic", italic => 1 )
      ->append( " " )
      ->append_tagged( "strike", strike => 1 );

   is( $str->build_markdown, "String with **bold** *italic* ~~strike~~",
      'build common codes' );
}

# formatting
{
   $String::Tagged::Markdown::HFM::HIGHLIGHT_COLOUR = Convert::Color->new( "rgb:1,1,0.7" );

   my $str = String::Tagged::Markdown::HFM->parse_markdown(
      "^super^ ~sub~ ++underline++ ==highlight== **bold** *italic* ~~strike~~"
   )->as_formatting;

   is( [ sort $str->tagnames ], [qw( bg bold italic sizepos strike under )],
      'Converted S:T:Formatting has correct tagnames' );
   is( $str->get_tag_at( 0, "sizepos" ), "super", 'Sizepos for superscript' );
   is( $str->get_tag_at( 6, "sizepos" ), "sub",   'Sizepos for subscript' );

   is( String::Tagged::Markdown::HFM->new_from_formatting( $str )->build_markdown,
      "^super^ ~sub~ ++underline++ ==highlight== **bold** *italic* ~~strike~~",
      'Reconstructed Markdown from S:T:Formatting' );
}

done_testing;
