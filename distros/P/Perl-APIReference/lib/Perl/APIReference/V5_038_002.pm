package Perl::APIReference::V5_038_002;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_038_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.038002';
  bless $obj => $class;

  return $obj;
}

1;
