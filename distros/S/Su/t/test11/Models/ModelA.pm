package Models::ModelA;
my $model = {
  field1 => "model_a_string",
  field2 => "model_a_number",
  field3 => "model_a_date",
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

