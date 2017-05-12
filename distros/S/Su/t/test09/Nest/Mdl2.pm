package Nest::Mdl2;
use strict;
use warnings;

my $model=
  {
    field1 => "value1",
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

