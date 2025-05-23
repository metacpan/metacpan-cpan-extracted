package Perl::APIReference::V5_040_001;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_040_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.040001';
  bless $obj => $class;

  return $obj;
}

1;
