package SQL::Wizard::Expr::Raw;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: sql => 'NOW()', bind => []
  $args{bind} ||= [];
  $class->SUPER::new(%args);
}

1;
