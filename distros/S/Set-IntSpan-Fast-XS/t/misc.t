#!perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Set::IntSpan::Fast::XS;

sub brute_force_card_in_range {
  my $lo   = shift;
  my $hi   = shift;
  my $card = 0;
  for my $el ( @_ ) {
    $card++ if $el >= $lo && $el <= $hi;
  }
  return $card;
}

{
  srand( 1 );
  my @members = ();
  my @sets = map { Set::IntSpan::Fast::XS->new() } ( 1 .. 7 );

  my $next = int( rand( 100 ) );
  for ( 1 .. 40 ) {
    push @members, $next;

    # Distribute among sets
    $sets[ $next % @sets ]->add( $next );
    $next += int( sqrt( rand( 5 ) ) ) + 1;
  }

  my $set = Set::IntSpan::Fast::XS->new();
  $set->add( @members );
  my @got = ();
  for my $i ( $members[0] - 1 .. $members[-1] + 1 ) {
    push @got, $i if $set->contains( $i );
  }

  is_deeply( \@got, \@members, 'contains' );

  is( $set->cardinality(), scalar( @members ), 'cardinality' );

  # Test the cardinality of various ranges
  my $min    = $members[0];
  my $max    = $members[-1];
  my $stride = int( ( $max - $min ) / 5 );
  for ( my $lo = $min - $stride * 2; $lo <= $max + $stride * 2; $lo++ )
  {
    my $hi   = $lo + $stride;
    my $want = brute_force_card_in_range( $lo, $hi, @members );
    my $got  = $set->cardinality( $lo, $hi );
    is( $got, $want, "cardinality for $lo to $hi OK" );
  }

  my $copy = $set->copy();
  isa_ok $copy, 'Set::IntSpan::Fast::XS';
  my @orig = $set->as_array();
  my @copy = $copy->as_array();

  is_deeply( \@copy, \@orig, 'copy' );

  # Union
  my $first  = shift @sets;
  my $merged = $first->union( @sets );
  isa_ok $merged, 'Set::IntSpan::Fast::XS';
  @got = $merged->as_array();
  is_deeply( \@got, \@members, 'union' );

  # Intersection
  for ( @sets ) {
    $_->merge( $first );
  }

  my $inter = $sets[0]->intersection( @sets[ 1 .. $#sets ] );

  my @common = $inter->as_array();
  my @first  = $first->as_array();
  is_deeply( \@common, \@first, 'intersection' );
}

{
  my @s1  = ( 1, 2, 3, 4, 5, 6 );
  my @s2  = ( 2, 4, 6, 7, 8, 9 );
  my @xor = ( 1, 3, 5, 7, 8, 9 );

  my $set1 = Set::IntSpan::Fast::XS->new();
  $set1->add( @s1 );
  my $set2 = Set::IntSpan::Fast::XS->new();
  $set2->add( @s2 );
  my @got = $set1->xor( $set2 )->as_array();
  is_deeply( \@got, \@xor, 'xor' );
}

{
  my @s1 = ( 1, 2, 3, 4, 5, 6 );
  my @s2 = ( 2, 4, 6, 7, 8, 9 );
  my @diff = ( 1, 3, 5 );

  my $set1 = Set::IntSpan::Fast::XS->new();
  $set1->add( @s1 );
  my $set2 = Set::IntSpan::Fast::XS->new();
  $set2->add( @s2 );
  my @got = $set1->diff( $set2 )->as_array();
  is_deeply( \@got, \@diff, 'diff' );
}

{
  my @sets = ();
  for ( 0 .. 3 ) {
    my $s = Set::IntSpan::Fast::XS->new();
    $s->add( 1, 3, 5, 7, 9 );
    $s->add_range( 100, 1_000_000 );
    push @sets, $s;
  }

  ok( $sets[0]->equals( @sets[ 1 .. $#sets ] ), 'equal' );
  for ( 0 .. 3 ) {
    $sets[$_]->add( 6 );
    my $eq = $sets[0]->equals( @sets[ 1 .. $#sets ] );
    $eq = !$eq unless $_ == 3;
    ok( $eq, "equal $_" );
  }

  # Equal sets are supersets and subsets of each other
  ok( $sets[0]->superset( $sets[1] ), 'superset equal' );
  ok( $sets[0]->subset( $sets[1] ),   'subset equal' );

  $sets[0]->add( 11 );
  ok( $sets[0]->superset( $sets[1] ), 'superset bigger' );
  ok( !$sets[0]->subset( $sets[1] ),  'subset bigger' );
}

{
  my @sets = map { Set::IntSpan::Fast::XS->new(); } ( 1 .. 3 );
  ok( $sets[0]->equals( $sets[1] ),        'empty sets equal' );
  ok( $sets[0]->equals( @sets[ 1 .. 2 ] ), 'three empty sets equal' );
  $sets[0]->add( 0 );
  ok( !$sets[0]->equals( $sets[1] ),        'sets not equal' );
  ok( !$sets[0]->equals( @sets[ 1 .. 2 ] ), 'three sets not equal 1' );
  ok( !$sets[2]->equals( @sets[ 0 .. 1 ] ), 'three sets not equal 2' );
  ok( !$sets[1]->equals( @sets[ 0, 2 ] ), 'three sets not equal 3' );
  $sets[1]->add( 0 );
  ok( !$sets[0]->equals( @sets[ 1 .. 2 ] ), 'three sets not equal 4' );
  ok( !$sets[2]->equals( @sets[ 0 .. 1 ] ), 'three sets not equal 5' );
  ok( !$sets[1]->equals( @sets[ 0, 2 ] ), 'three sets not equal 6' );
  $sets[2]->add( 0 );
  ok( $sets[0]->equals( @sets[ 1 .. 2 ] ), 'three sets equal 1' );
  ok( $sets[2]->equals( @sets[ 0 .. 1 ] ), 'three sets equal 2' );
  ok( $sets[1]->equals( @sets[ 0, 2 ] ), 'three sets equal 3' );
}

{
  my $set = Set::IntSpan::Fast::XS->new();
  is( $set->as_string(), '', 'empty as_string' );
  $set->add( 1 );
  is( $set->as_string(), '1', 'single element' );
  $set->add_range( 3, 1_000_000 );
  is( $set->as_string(), '1,3-1000000', 'range' );
}

{
  my $set = Set::IntSpan::Fast::XS->new();
  ok( !$set->contains_any( 0 ), 'empty contains_any' );
  $set->add( 3 );
  ok( !$set->contains_any( 0, 2, 4, 6 ), 'false contains_any' );
  $set->add_range( -3, 3 );
  ok( $set->contains_any( -4, 0 ), 'range contains_any' );
}
