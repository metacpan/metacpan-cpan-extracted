package SQL::Wizard::Expr::Window;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: expr => $func_expr, spec => { name => 'w' } or { -partition_by => ..., -order_by => ..., -frame => ... }
  $class->SUPER::new(%args);
}

1;
