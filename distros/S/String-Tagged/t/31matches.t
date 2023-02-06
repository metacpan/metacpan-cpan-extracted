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

done_testing;
