package Models::Model01;
my $model = {
  key1 => 'val1_1',
  key2 => 'val1_2',
  key3 => 'val1_3',
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

