package Template::Plugin::GoSplat;
use Template::Plugin::Procedural;
@ISA = (Template::Plugin::Procedural);

sub gosplat
{
  my $string = shift;
  return join 'splat', split //, $string;
}
