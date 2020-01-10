use strict; use warnings;
package TestML::Bridge;

sub new {
  my $class = shift;

  bless {@_}, $class;
}

1;
