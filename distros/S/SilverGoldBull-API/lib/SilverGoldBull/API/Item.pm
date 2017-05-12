package SilverGoldBull::API::Item;

use strict;
use warnings;

use Mouse;
with qw(SilverGoldBull::API::CommonMethodsRole);

has 'id'        => ( is => 'rw', isa => 'Str', required => 1 );
has 'bid_price' => ( is => 'rw', isa => 'Num', required => 0 );
has 'qty'       => ( is => 'rw', isa => 'Int', required => 1 );

sub to_hashref {
  my ($self) = @_;
  my $hashref = {};
  for my $field (qw(id bid_price qty)) {
    if (defined $self->{$field}) {
      $hashref->{$field} = $self->{$field};
    }
  }
  
  return $hashref;
}

1;