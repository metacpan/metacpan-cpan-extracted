package Perl::APIReference::V5_012_001;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_012_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.012001';
  bless $obj => $class;

  return $obj;
}

1;
