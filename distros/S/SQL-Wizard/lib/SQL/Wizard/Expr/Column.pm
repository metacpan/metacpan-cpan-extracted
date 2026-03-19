package SQL::Wizard::Expr::Column;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# args: name => 'u.id'

1;
