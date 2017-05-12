package ORTestTiedRemote;

use Moo;

use Tie::Array;
use Tie::Hash;

has hash => ( is => 'ro',  builder => 1 );
has array => ( is => 'ro', builder => 1 );

sub _build_hash {
  tie(my %hash, 'Tie::StdHash');
  %hash = ( akey => 'a value');
  return \%hash;
}

sub _build_array {
  tie(my @array, 'Tie::StdArray');
  @array = ('another value');
  return \@array;
}

sub sum_array {
  my ($self) = @_;
  my $sum = 0;

  foreach(@{$self->array}) {
    $sum += $_;
  }

  return $sum;
}

sub sum_hash {
  my ($self) = @_;
  my $sum = 0;

  foreach(values(%{$self->hash})) {
    $sum += $_;
  }

  return $sum;
}

1;

