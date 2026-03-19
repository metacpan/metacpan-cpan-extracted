package SQL::Wizard::Expr::Value;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# args: value => 'some string'

1;
