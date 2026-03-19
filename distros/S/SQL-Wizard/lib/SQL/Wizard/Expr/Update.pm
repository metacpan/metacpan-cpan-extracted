package SQL::Wizard::Expr::Update;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: table => 'users' or [...with joins], set => {...},
  #       where => {...}, from => [...], returning => [...], limit => $n
  $class->SUPER::new(%args);
}

1;
