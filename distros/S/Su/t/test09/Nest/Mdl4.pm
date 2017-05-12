package Nest::Mdl4;
use strict;
use warnings;

my $model=
  {
    field1 =>
      {
        key2 => "value2",
        key1 => "value1",
      },
    field2 => "value3",
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

