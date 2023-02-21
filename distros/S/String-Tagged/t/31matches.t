#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $str = String::Tagged->new( "Here is %s with %d" )
   ->apply_tag( 3, 7, tag => "value" );

my @subs = map {
   [ $_->str, $_->get_tags_at( 0 ) ]
} $str->matches( qr/\S+/ );

is( \@subs,
   [ [ "Here", {} ],
     [ "is", { tag => "value" } ],
     [ "%s", { tag => "value" } ],
     [ "with", {} ],
     [ "%d", {} ] ],
   'Result of ->matches' );

{
   my @extents = $str->match_extents( qr/\S+/ );
   is( scalar @extents, 5, '->match_extents yields 5 extents' );

   my $e = $extents[0];

   can_ok( $e, [qw( string start length end substr )], 'First extent is right class' );
   ref_is( $e->string, $str, '$e->string' );
   is( $e->start, 0, '$e->start' );
   is( $e->length, 4, '$e->length' );
   is( $e->substr, "Here", '$e->substr' );
}

{
   $str = String::Tagged->new( "1 23 456 7890" );

   foreach my $e ( reverse $str->match_extents( qr/\d+/ ) ) {
      $str->set_substr( $e->start, $e->length, "digits" );
   }

   is( "$str", "digits digits digits digits",
      'match_extents in reverse can be safely used for set_substr' );
}

done_testing;
