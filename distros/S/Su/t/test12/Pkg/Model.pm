package Pkg::Model;
use strict;
use warnings;

my $model=
  {
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

