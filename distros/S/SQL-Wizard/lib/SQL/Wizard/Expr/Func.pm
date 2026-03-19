package SQL::Wizard::Expr::Func;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: name => 'COUNT', args => [...]
  $args{args} ||= [];
  $class->SUPER::new(%args);
}

1;
