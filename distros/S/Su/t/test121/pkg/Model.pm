package pkg::Model;
use strict;
use warnings;

my $model = {
  key1            => 'value1',
  pre__key1       => 'pre_val',
  key1__post      => 'post_val',
  pre__key1__post => 'pre_post_val',
};

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

