package SQL::Wizard::Expr;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

use overload
  '+'    => sub { _binop('+',  @_) },
  '-'    => sub { _binop('-',  @_) },
  '*'    => sub { _binop('*',  @_) },
  '/'    => sub { _binop('/',  @_) },
  '%'    => sub { _binop('%',  @_) },
  '""'   => sub { croak "Cannot stringify SQL::Wizard::Expr directly; use ->to_sql" },
  'bool' => sub { 1 },
  fallback => 1;

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

sub to_sql {
  my ($self, $renderer) = @_;
  $renderer ||= $self->{_renderer};
  croak "No renderer available" unless $renderer;
  $renderer->render($self);
}

sub as {
  my ($self, $alias) = @_;
  require SQL::Wizard::Expr::Alias;
  SQL::Wizard::Expr::Alias->new(
    expr      => $self,
    alias     => $alias,
    _renderer => $self->{_renderer},
  );
}

sub asc {
  my ($self) = @_;
  require SQL::Wizard::Expr::Order;
  SQL::Wizard::Expr::Order->new(
    expr      => $self,
    direction => 'ASC',
    _renderer => $self->{_renderer},
  );
}

sub desc {
  my ($self) = @_;
  require SQL::Wizard::Expr::Order;
  SQL::Wizard::Expr::Order->new(
    expr      => $self,
    direction => 'DESC',
    _renderer => $self->{_renderer},
  );
}

sub asc_nulls_first {
  my ($self) = @_;
  require SQL::Wizard::Expr::Order;
  SQL::Wizard::Expr::Order->new(
    expr      => $self,
    direction => 'ASC',
    nulls     => 'FIRST',
    _renderer => $self->{_renderer},
  );
}

sub desc_nulls_last {
  my ($self) = @_;
  require SQL::Wizard::Expr::Order;
  SQL::Wizard::Expr::Order->new(
    expr      => $self,
    direction => 'DESC',
    nulls     => 'LAST',
    _renderer => $self->{_renderer},
  );
}

sub over {
  my ($self, @args) = @_;
  require SQL::Wizard::Expr::Window;
  # over('window_name') or over(-partition_by => ..., -order_by => ...)
  my $spec;
  if (@args == 1 && !ref $args[0]) {
    $spec = { name => $args[0] };
  } else {
    my %opts = @args;
    $spec = \%opts;
  }
  SQL::Wizard::Expr::Window->new(
    expr      => $self,
    spec      => $spec,
    _renderer => $self->{_renderer},
  );
}

sub _binop {
  my ($op, $left, $right, $swap) = @_;
  require SQL::Wizard::Expr::BinaryOp;
  # Coerce plain values to Value nodes
  $right = _coerce($right, $left);
  ($left, $right) = ($right, $left) if $swap;
  SQL::Wizard::Expr::BinaryOp->new(
    op        => $op,
    left      => $left,
    right     => $right,
    _renderer => $left->{_renderer},
  );
}

sub _coerce {
  my ($thing, $ref_expr) = @_;
  return $thing if blessed($thing) && $thing->isa('SQL::Wizard::Expr');
  require SQL::Wizard::Expr::Value;
  SQL::Wizard::Expr::Value->new(
    value     => $thing,
    _renderer => $ref_expr->{_renderer},
  );
}

1;
