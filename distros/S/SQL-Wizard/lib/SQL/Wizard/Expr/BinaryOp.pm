package SQL::Wizard::Expr::BinaryOp;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# args: op => '+', left => $expr, right => $expr

1;
