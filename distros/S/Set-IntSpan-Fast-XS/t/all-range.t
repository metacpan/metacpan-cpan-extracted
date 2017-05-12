use strict;
use warnings;
use Test::More tests => 242;
use Set::IntSpan::Fast::XS;

# Extend
package Set::IntSpan::Fast::XS;

# Reference implementation
sub alt_all_in_range {
  my ( $self, $lo, $hi ) = @_;
  my $range = __PACKAGE__->new;
  $range->add_range( $lo, $hi );
  return $self->intersection( $range )->equals( $range );
}

package main;

my $set = Set::IntSpan::Fast::XS->new( '1,3,5-6,9,11-14,18-100' );
for my $lo ( -1 .. 20 ) {
  for my $hi ( $lo .. $lo + 10 ) {
    my $want = $set->alt_all_in_range( $lo, $hi );
    my $got = $set->contains_all_range( $lo, $hi );
    ok !$want == !$got, "$lo .. $hi";
  }
}
