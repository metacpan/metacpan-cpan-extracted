package Models::MenuModel;
my $model = {
  field1 => { type => "value1" },
  field2 => { type => "value2" },
  field3 => { type => "value3" },
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

