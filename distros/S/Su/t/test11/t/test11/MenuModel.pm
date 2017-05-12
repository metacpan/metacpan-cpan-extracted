package MenuModel;
my $model=
  {
    field1 => {type => "string"},
    field2 => {type => "number"},
    field3 => {type => "date"},
};

sub model{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $arg = shift;
  if($arg){
    $model = $arg;
  }else{
    return $model;
  }

}

1;

