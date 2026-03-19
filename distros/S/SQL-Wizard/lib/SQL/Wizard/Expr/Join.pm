package SQL::Wizard::Expr::Join;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: type => 'JOIN'|'LEFT JOIN'|..., table => 'orders|o' or $subselect, on => '...' or {...}
  $class->SUPER::new(%args);
}

1;
