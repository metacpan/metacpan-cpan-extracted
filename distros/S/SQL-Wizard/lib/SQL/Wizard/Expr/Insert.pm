package SQL::Wizard::Expr::Insert;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: into => 'table', values => {...} or [[...],[...]], columns => [...],
  #       select => $select, on_conflict => {...}, on_duplicate => {...}, returning => [...]
  $class->SUPER::new(%args);
}

1;
