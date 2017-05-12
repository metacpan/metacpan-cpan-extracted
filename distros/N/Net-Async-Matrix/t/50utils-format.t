#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Async::Matrix::Utils qw( parse_formatted_message build_formatted_message );

# unformatted
{
   my $body = parse_formatted_message( {
      body => "Here is some plain text",
   } );

   isa_ok( $body, "String::Tagged", '$body' );

   is( $body->str, "Here is some plain text", 'body string' );
   is( scalar $body->tagnames, 0, 'body has no tags' );

   my $content = build_formatted_message(
      "A plain text reply",
   );

   is_deeply( $content,
      { body => "A plain text reply" },
      'content of plain string' );

   is_deeply( build_formatted_message( String::Tagged->new( "No actual tags" ) ),
      { body => "No actual tags" },
      'content of String::Tagged with no tags' );
}

# HTML formatted
SKIP: {
   skip "No HTML::TreeBuilder", 1 unless Net::Async::Matrix::Utils::CAN_PARSE_HTML;

   my $body = parse_formatted_message( {
      body => "A body with bold and green text",
      format => "org.matrix.custom.html",
      formatted_body => 'A body with <b>bold</b> and <font color="green">green</font> text',
   } );

   isa_ok( $body, "String::Tagged", '$body' );

   is( $body->str, "A body with bold and green text", 'body string' );

   ok( $body->get_tags_at( index $body, "bold" )->{bold}, 'body has bold' );
   is( $body->get_tag_extent( index( $body, "bold" ), "bold" )->length, 4, 'bold tag correct length' );
   ok( my $fg = $body->get_tags_at( index $body, "green" )->{fg}, 'body has fg' );
   is( $fg->name, "green", '$fg colour name' );
}
SKIP: {
   skip "No String::Tagged::HTML", 1 unless Net::Async::Matrix::Utils::CAN_BUILD_HTML;

   my $content = build_formatted_message(
      String::Tagged->new
         ->append       ( "Response with " )
         ->append_tagged( "italic", italic => 1 )
         ->append       ( " and " )
         ->append_tagged( "green", fg => Convert::Color->new( 'vga:green' ) )
   );

   is_deeply( $content,
      { body => "Response with italic and green",
        format => "org.matrix.custom.html",
        formatted_body => 'Response with <em>italic</em> and <font color="lime">green</font>',
      },
      'content of HTML formatted string' );
}

done_testing;
