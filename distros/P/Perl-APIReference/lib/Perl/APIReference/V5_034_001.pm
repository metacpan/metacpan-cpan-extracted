package Perl::APIReference::V5_034_001;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_034_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.034001';
  bless $obj => $class;

  return $obj;
}

1;
