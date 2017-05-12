package test09::Models::NewModelWithArg;
use strict;
use warnings;

my $model=
  {
    field1 => "string",
    field2 => "number",
    field3 => "date",
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

