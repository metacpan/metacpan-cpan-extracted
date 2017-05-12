package Models::Model03;
my $model = {
  key1 => 'val3_1',
  key2 => 'val3_2',
  key3 => 'val3_3',
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

