package SQL::Wizard::Expr::Order;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# args: expr => $expr_obj, direction => 'ASC'|'DESC', nulls => 'FIRST'|'LAST' (optional)

1;
