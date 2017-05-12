package Perl::APIReference::V5_016_003;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_016_002';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.016003';
  bless $obj => $class;
  return $obj;
}

1;
