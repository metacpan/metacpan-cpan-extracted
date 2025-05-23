package Perl::APIReference::V5_024_001;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_024_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.024001';
  bless $obj => $class;

  return $obj;
}

1;
