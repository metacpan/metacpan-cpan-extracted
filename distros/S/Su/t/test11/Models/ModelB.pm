package Models::ModelB;
my $model = {
  field1 => "model_b_string",
  field2 => "model_b_number",
  field3 => "model_b_date",
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

