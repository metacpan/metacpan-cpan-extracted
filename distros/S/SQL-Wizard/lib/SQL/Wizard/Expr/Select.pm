package SQL::Wizard::Expr::Select;

use strict;
use warnings;
use Storable qw(dclone);
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  $class->SUPER::new(%args);
}

# Immutable modifiers — return cloned objects

sub add_where {
  my ($self, $extra) = @_;
  my $clone = dclone($self);
  if ($clone->{where}) {
    $clone->{where} = [-and => $clone->{where}, $extra];
  } else {
    $clone->{where} = $extra;
  }
  $clone;
}

sub columns {
  my ($self, $cols) = @_;
  my $clone = dclone($self);
  $clone->{columns} = $cols;
  $clone;
}

sub order_by {
  my ($self, @order) = @_;
  my $clone = dclone($self);
  $clone->{order_by} = @order == 1 ? $order[0] : \@order;
  $clone;
}

sub limit {
  my ($self, $limit) = @_;
  my $clone = dclone($self);
  $clone->{limit} = $limit;
  $clone;
}

sub offset {
  my ($self, $offset) = @_;
  my $clone = dclone($self);
  $clone->{offset} = $offset;
  $clone;
}

# Compound query methods

sub union {
  my ($self, $other) = @_;
  require SQL::Wizard::Expr::Compound;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'UNION', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub union_all {
  my ($self, $other) = @_;
  require SQL::Wizard::Expr::Compound;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'UNION ALL', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub intersect {
  my ($self, $other) = @_;
  require SQL::Wizard::Expr::Compound;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'INTERSECT', query => $other }],
    _renderer => $self->{_renderer},
  );
}

sub except {
  my ($self, $other) = @_;
  require SQL::Wizard::Expr::Compound;
  SQL::Wizard::Expr::Compound->new(
    queries   => [{ type => undef, query => $self }, { type => 'EXCEPT', query => $other }],
    _renderer => $self->{_renderer},
  );
}

1;
