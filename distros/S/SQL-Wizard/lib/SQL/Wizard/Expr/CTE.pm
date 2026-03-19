package SQL::Wizard::Expr::CTE;

use strict;
use warnings;
use parent 'SQL::Wizard::Expr';

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
  require SQL::Wizard::Expr::Select;
  my %node;
  $node{columns}  = $args{'-columns'}  if $args{'-columns'};
  $node{from}     = $args{'-from'}     if $args{'-from'};
  $node{where}    = $args{'-where'}    if $args{'-where'};
  $node{group_by} = $args{'-group_by'} if $args{'-group_by'};
  $node{having}   = $args{'-having'}   if $args{'-having'};
  $node{order_by} = $args{'-order_by'} if $args{'-order_by'};
  $node{limit}    = $args{'-limit'}    if defined $args{'-limit'};
  $node{offset}   = $args{'-offset'}   if defined $args{'-offset'};
  $node{window}   = $args{'-window'}   if $args{'-window'};
  SQL::Wizard::Expr::Select->new(
    %node,
    _cte      => $self,
    _renderer => $self->{_renderer},
  );
}

1;
