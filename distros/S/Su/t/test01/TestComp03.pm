package TestComp03;
use Su::Template;

sub process{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $arg = shift;
  return "TestComp03 " .$arg;

}

1;
