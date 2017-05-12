package Models::ModelC;
my $model = {
  field1 => "model_c_string",
  field2 => "model_c_number",
  field3 => "model_c_date",
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

