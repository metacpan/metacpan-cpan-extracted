package Perl::APIReference::V5_014_004;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_014_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.014004';
  bless $obj => $class;

  return $obj;
}

1;
