package builder::custom;
use strict;
use warnings;
use warnings FATAL => qw(recursion);
use parent qw(Module::Build);


sub new {
  my ($class, %args) = @_;
  die "OS Unsupported" if ($^O !~ m#(?i)Linux#);
  return $class->SUPER::new(%args);
}

1;
