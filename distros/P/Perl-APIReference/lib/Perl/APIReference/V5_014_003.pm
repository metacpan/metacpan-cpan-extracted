package Perl::APIReference::V5_014_003;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_014_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.014003';
  bless $obj => $class;

  return $obj;
}

1;
