package Models::Model02;
my $model = {
  key1 => 'val2_1',
  key2 => 'val2_2',
  key3 => 'val2_3',
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

