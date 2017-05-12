package Template::Plugin::ReverseVMethod;
use Template::Plugin::VMethods;
@ISA = qw(Template::Plugin::VMethods);
@SCALAR_OPS = qw(reverse);

sub reverse
{
  my $string = shift;
  scalar reverse $string;
}

1;

