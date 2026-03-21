package SQL::Wizard::Expr::Select;

use strict;
use warnings;
use Storable qw(dclone);
use parent 'SQL::Wizard::Expr';
use SQL::Wizard::Expr::Compound;

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# Build a Select node from the standard -key => value API args.
# Accepts extra key/value pairs (e.g. _cte, _renderer) merged in.
sub from_args {
  my ($class, %args) = @_;
  Carp::confess("select requires -from") unless $args{'-from'};
  my %node;
  $node{distinct} = $args{'-distinct'}  if $args{'-distinct'};
  $node{columns}  = $args{'-columns'}  if $args{'-columns'};
  $node{from}     = $args{'-from'}     if $args{'-from'};
  $node{where}    = $args{'-where'}    if $args{'-where'};
  $node{group_by} = $args{'-group_by'} if $args{'-group_by'};
  $node{having}   = $args{'-having'}   if $args{'-having'};
  $node{order_by} = $args{'-order_by'} if $args{'-order_by'};
  $node{limit}    = $args{'-limit'}    if defined $args{'-limit'};
  $node{offset}   = $args{'-offset'}   if defined $args{'-offset'};
  $node{window}   = $args{'-window'}   if $args{'-window'};
  $node{_cte}      = $args{_cte}       if $args{_cte};
  $node{_renderer} = $args{_renderer}  if $args{_renderer};
  $class->new(%node);
}

# Immutable modifiers — return cloned objects

sub distinct {
  my ($self) = @_;
  my $clone = dclone($self);
  $clone->{distinct} = 1;
  return $clone;
}

sub where {
  my ($self, $where) = @_;
  my $clone = dclone($self);
  $clone->{where} = $where;
  return $clone;
}

sub add_where {
  my ($self, $extra) = @_;
  my $clone = dclone($self);
  if ($clone->{where}) {
    $clone->{where} = [-and => $clone->{where}, $extra];
  } else {
    $clone->{where} = $extra;
  }
  return $clone;
}

sub columns {
  my ($self, $cols) = @_;
  my $clone = dclone($self);
  $clone->{columns} = $cols;
  return $clone;
}

sub order_by {
  my ($self, @order) = @_;
  my $clone = dclone($self);
  $clone->{order_by} = @order == 1 ? $order[0] : \@order;
  return $clone;
}

sub limit {
  my ($self, $limit) = @_;
  my $clone = dclone($self);
  $clone->{limit} = $limit;
  return $clone;
}

sub offset {
  my ($self, $offset) = @_;
  my $clone = dclone($self);
  $clone->{offset} = $offset;
  return $clone;
}

# Compound query methods

sub union {
  my ($self, $other) = @_;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'UNION', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub union_all {
  my ($self, $other) = @_;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'UNION ALL', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub intersect {
  my ($self, $other) = @_;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'INTERSECT', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub except {
  my ($self, $other) = @_;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'EXCEPT', query => $other }],
    _renderer => $self->{_renderer},
  );
}

1;
