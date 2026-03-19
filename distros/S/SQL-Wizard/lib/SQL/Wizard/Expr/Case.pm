package SQL::Wizard::Expr::Case;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args:
  #   whens    => [ { condition => ..., then => ... }, ... ]
  #   else     => $expr (optional)
  #   operand  => $expr (optional, for CASE ON)
  $class->SUPER::new(%args);
}

1;
