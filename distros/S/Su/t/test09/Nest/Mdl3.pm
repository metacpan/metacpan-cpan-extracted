package Nest::Mdl3;
use strict;
use warnings;

my $model=
  {
    field2 => "value2",
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

