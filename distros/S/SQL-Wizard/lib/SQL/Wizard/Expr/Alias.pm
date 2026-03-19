package SQL::Wizard::Expr::Alias;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# args: expr => $expr_obj, alias => 'name'

1;
