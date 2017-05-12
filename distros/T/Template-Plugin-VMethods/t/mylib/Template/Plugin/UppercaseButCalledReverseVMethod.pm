package Template::Plugin::UppercaseButCalledReverseVMethod;
use Template::Plugin::VMethods;
@ISA = qw(Template::Plugin::VMethods);
@SCALAR_OPS = qw(reverse);

sub reverse
{
  my $string = shift;
  scalar uc $string;
}

1;

