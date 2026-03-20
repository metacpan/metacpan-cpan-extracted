package SQL::Wizard::Expr::CTE;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';
use SQL::Wizard::Expr::Select;

sub new {
  my ($class, %args) = @_;
  # args:
  #   ctes      => [ { name => 'recent', query => $select }, ... ]
  #   recursive => 0|1
  $class->SUPER::new(%args);
}

# Chain the main SELECT after WITH
sub select {
  my ($self, %args) = @_;
  SQL::Wizard::Expr::Select->from_args(%args, _cte => $self, _renderer => $self->{_renderer});
}

1;
