#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $str = String::Tagged->new( "Tag [] here" );

$str->apply_tag( 5, 0, zero => "length" );

is( [ $str->tagnames ], [qw( zero )], '->tagnames sees zero-length tag' );

# ->iter_tags sees the zero-width tag
{
   my $found;
   $str->iter_tags( sub {
      my ( $s, $l, $n, $v ) = @_;
      is( $s, 5, 'tag begins at 5' );
      is( $l, 0, 'tag length is 0' );
      is( $n, "zero", 'tag name is zero' );
      is( $v, "length", 'tag value is length' );
      $found++;
   } );
   ok( $found, '->iter_tags sees zero-length tag' );
}

# ->iter_substr_nooverlap sees the zero-width tag
{
   my $found;
   $str->iter_substr_nooverlap( sub {
      my ( $sub, %tags ) = @_;
      return unless $tags{zero};

      is( $sub, "", 'substr for zerolength tag is empty' );
      is( $tags{zero}, "length", 'tag name/value' );
      $found++;
   } );
   ok( $found, '->iter_substr_nooverlap sees zero-length tag' );
}

# zero-length tags copied by append
{
   my $new = String::Tagged->new( "" );
   $new .= $str;

   is( [ $str->tagnames ], [qw( zero )], '->tagnames of copy contains zero-length tag' );
}

# ->debug_sprintf
{
   my $out = $str->debug_sprintf;
   is( $out, <<'EOF', '->debug_sprintf sees zero-length tag' );
  Tag [] here
      ><       zero => length
EOF
}

# zero-length string can have tags
{
   my $zero = String::Tagged->new_tagged(
      "", zero => "here"
   );

   is( [ $zero->tagnames ], [qw( zero )], '->tagnames on zerolength' );

   {
      my $found;
      $zero->iter_tags( sub {
         my ( $s, $l, $n, $v ) = @_;
         is( $s, 0, 'tag begins at 0' );
         is( $l, 0, 'tag length is 0' );
         is( $n, "zero", 'tag name is zero' );
         is( $v, "here", 'tag value is here' );
         $found++;
      } );
      ok( $found, '->iter_tags on zerolength' );
   }

   {
      my $found;
      $zero->iter_substr_nooverlap( sub {
         my ( $sub, %tags ) = @_;
         return unless $tags{zero};

         is( $sub, "", 'substr for zerolength tag is empty' );
         is( $tags{zero}, "here", 'tag name/value' );
         $found++;
      } );
      ok( $found, '->iter_substr_nooverlap on zerolength' );
   }

   {
      my $str = String::Tagged->new( "more" );
      $str .= $zero;

      is( [ $str->tagnames ], [qw( zero )], '->tagnames string appended with zerolength' );
   }
}

done_testing;
