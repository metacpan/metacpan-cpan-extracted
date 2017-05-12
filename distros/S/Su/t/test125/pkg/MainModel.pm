package pkg::MainModel;
use strict;
use warnings;

my $model = { key1 => 'value1' };

sub model {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $arg = shift;
  if ($arg) {
    $model = $arg;
  } else {
    return $model;
  }

} ## end sub model

1;

