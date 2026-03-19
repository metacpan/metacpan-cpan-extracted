package SQL::Wizard::Expr::Delete;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: from => 'users', where => {...}, using => '...', returning => [...]
  $class->SUPER::new(%args);
}

1;
