package SQL::Wizard;

use strict;
use warnings;
use Carp;

our $VERSION = '0.03';

use SQL::Wizard::Renderer;
use SQL::Wizard::Expr::Column;
use SQL::Wizard::Expr::Value;
use SQL::Wizard::Expr::Raw;
use SQL::Wizard::Expr::Func;
use SQL::Wizard::Expr::Case;
use SQL::Wizard::Expr::Join;
use SQL::Wizard::Expr::Select;
use SQL::Wizard::Expr::Insert;
use SQL::Wizard::Expr::Update;
use SQL::Wizard::Expr::Delete;
use SQL::Wizard::Expr::CTE;

sub new {
  my ($class, %args) = @_;
  my $self = bless {
    dialect  => $args{dialect} || 'ansi',
    renderer => SQL::Wizard::Renderer->new(dialect => $args{dialect} || 'ansi'),
  }, $class;
  $self;
}

## Expression primitives

sub col {
  my ($self, $name) = @_;
  SQL::Wizard::Expr::Column->new(
    name      => $name,
    _renderer => $self->{renderer},
  );
}

sub val {
  my ($self, $value) = @_;
  SQL::Wizard::Expr::Value->new(
    value     => $value,
    _renderer => $self->{renderer},
  );
}

sub raw {
  my ($self, $sql, @bind) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => $sql,
    bind      => \@bind,
    _renderer => $self->{renderer},
  );
}

sub func {
  my ($self, $name, @args) = @_;
  # Coerce plain strings/values: strings in func args are column refs
  my @coerced = map {
    ref $_ ? $_ : SQL::Wizard::Expr::Column->new(
      name      => $_,
      _renderer => $self->{renderer},
    )
  } @args;
  SQL::Wizard::Expr::Func->new(
    name      => $name,
    args      => \@coerced,
    _renderer => $self->{renderer},
  );
}

## Query builders

sub select {
  my ($self, %args) = @_;
  SQL::Wizard::Expr::Select->from_args(%args, _renderer => $self->{renderer});
}

sub insert {
  my ($self, %args) = @_;
  my %node;
  $node{into}         = $args{'-into'}         if $args{'-into'};
  $node{values}       = $args{'-values'}       if $args{'-values'};
  $node{columns}      = $args{'-columns'}      if $args{'-columns'};
  $node{select}       = $args{'-select'}       if $args{'-select'};
  $node{on_conflict}  = $args{'-on_conflict'}  if $args{'-on_conflict'};
  $node{on_duplicate} = $args{'-on_duplicate'} if $args{'-on_duplicate'};
  $node{returning}    = $args{'-returning'}    if $args{'-returning'};
  # Coerce hash values to Value nodes for bind params
  if (ref $node{values} eq 'HASH') {
    for my $k (keys %{$node{values}}) {
      my $v = $node{values}{$k};
      next if ref $v;
      $node{values}{$k} = SQL::Wizard::Expr::Value->new(
        value     => $v,
        _renderer => $self->{renderer},
      );
    }
  } elsif (ref $node{values} eq 'ARRAY') {
    # Multi-row: coerce each cell
    for my $row (@{$node{values}}) {
      for my $i (0 .. $#$row) {
        next if ref $row->[$i];
        $row->[$i] = SQL::Wizard::Expr::Value->new(
          value     => $row->[$i],
          _renderer => $self->{renderer},
        );
      }
    }
  }
  SQL::Wizard::Expr::Insert->new(
    %node,
    _renderer => $self->{renderer},
  );
}

sub update {
  my ($self, %args) = @_;
  my %node;
  $node{table}     = $args{'-table'}     if $args{'-table'};
  $node{set}       = $args{'-set'}       if $args{'-set'};
  $node{where}     = $args{'-where'}     if $args{'-where'};
  $node{from}      = $args{'-from'}      if $args{'-from'};
  $node{limit}     = $args{'-limit'}     if defined $args{'-limit'};
  $node{returning} = $args{'-returning'} if $args{'-returning'};
  # Coerce set values
  if (ref $node{set} eq 'HASH') {
    for my $k (keys %{$node{set}}) {
      my $v = $node{set}{$k};
      next if ref $v;
      $node{set}{$k} = SQL::Wizard::Expr::Value->new(
        value     => $v,
        _renderer => $self->{renderer},
      );
    }
  }
  SQL::Wizard::Expr::Update->new(
    %node,
    _renderer => $self->{renderer},
  );
}

sub delete {
  my ($self, %args) = @_;
  my %node;
  $node{from}      = $args{'-from'}      if $args{'-from'};
  $node{where}     = $args{'-where'}     if $args{'-where'};
  $node{using}     = $args{'-using'}     if $args{'-using'};
  $node{returning} = $args{'-returning'} if $args{'-returning'};
  SQL::Wizard::Expr::Delete->new(
    %node,
    _renderer => $self->{renderer},
  );
}

## Join helpers

sub join {
  my ($self, $table, $on) = @_;
  SQL::Wizard::Expr::Join->new(
    type      => 'JOIN',
    table     => $table,
    on        => $on,
    _renderer => $self->{renderer},
  );
}

sub left_join {
  my ($self, $table, $on) = @_;
  SQL::Wizard::Expr::Join->new(
    type      => 'LEFT JOIN',
    table     => $table,
    on        => $on,
    _renderer => $self->{renderer},
  );
}

sub right_join {
  my ($self, $table, $on) = @_;
  SQL::Wizard::Expr::Join->new(
    type      => 'RIGHT JOIN',
    table     => $table,
    on        => $on,
    _renderer => $self->{renderer},
  );
}

sub full_join {
  my ($self, $table, $on) = @_;
  SQL::Wizard::Expr::Join->new(
    type      => 'FULL OUTER JOIN',
    table     => $table,
    on        => $on,
    _renderer => $self->{renderer},
  );
}

sub cross_join {
  my ($self, $table) = @_;
  SQL::Wizard::Expr::Join->new(
    type      => 'CROSS JOIN',
    table     => $table,
    _renderer => $self->{renderer},
  );
}

## CASE expressions

sub case {
  my ($self, @args) = @_;
  my ($whens, $else) = $self->_parse_case_args(@args);
  SQL::Wizard::Expr::Case->new(
    whens     => $whens,
    ($else ? (else => $else) : ()),
    _renderer => $self->{renderer},
  );
}

sub case_on {
  my ($self, $operand, @args) = @_;
  my ($whens, $else) = $self->_parse_case_args(@args);
  SQL::Wizard::Expr::Case->new(
    operand   => $operand,
    whens     => $whens,
    ($else ? (else => $else) : ()),
    _renderer => $self->{renderer},
  );
}

sub _parse_case_args {
  my ($self, @args) = @_;
  my @whens;
  my $else;
  for my $arg (@args) {
    if (ref $arg eq 'ARRAY') {
      # [$q->when(...)] — a when clause
      push @whens, @$arg;
    } elsif (ref $arg eq 'HASH' && exists $arg->{_else}) {
      $else = $arg->{_else};
    }
  }
  return (\@whens, $else);
}

sub when {
  my ($self, $condition, $then) = @_;
  # Coerce then value
  $then = $self->val($then) unless ref $then;
  return { condition => $condition, then => $then };
}

sub else {
  my ($self, $value) = @_;
  $value = $self->val($value) unless ref $value;
  return { _else => $value };
}

## Condition helpers

sub exists {
  my ($self, $subquery) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'EXISTS',
    bind      => [],
    _subquery => $subquery,
    _renderer => $self->{renderer},
  );
}

sub not_exists {
  my ($self, $subquery) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'NOT EXISTS',
    bind      => [],
    _subquery => $subquery,
    _renderer => $self->{renderer},
  );
}

sub between {
  my ($self, $col, $lo, $hi) = @_;
  $col = $self->col($col) unless ref $col;
  $lo  = $self->val($lo)  unless ref $lo;
  $hi  = $self->val($hi)  unless ref $hi;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'BETWEEN',
    bind      => [],
    _between  => { col => $col, lo => $lo, hi => $hi },
    _renderer => $self->{renderer},
  );
}

sub not_between {
  my ($self, $col, $lo, $hi) = @_;
  $col = $self->col($col) unless ref $col;
  $lo  = $self->val($lo)  unless ref $lo;
  $hi  = $self->val($hi)  unless ref $hi;
  SQL::Wizard::Expr::Raw->new(
    sql          => 'NOT BETWEEN',
    bind         => [],
    _not_between => { col => $col, lo => $lo, hi => $hi },
    _renderer    => $self->{renderer},
  );
}

## Function shortcuts

sub cast {
  my ($self, $expr, $type) = @_;
  $expr = $self->col($expr) unless ref $expr;
  SQL::Wizard::Expr::Raw->new(
    sql       => "CAST",
    bind      => [],
    _cast     => { expr => $expr, type => $type },
    _renderer => $self->{renderer},
  );
}

sub coalesce { my $self = shift; $self->func('COALESCE', @_) }
sub greatest { my $self = shift; $self->func('GREATEST', @_) }
sub least    { my $self = shift; $self->func('LEAST', @_) }

## Boolean operators

sub and {
  my ($self, @conds) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'AND',
    bind      => [],
    _logic    => { op => 'AND', conds => \@conds },
    _renderer => $self->{renderer},
  );
}

sub or {
  my ($self, @conds) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'OR',
    bind      => [],
    _logic    => { op => 'OR', conds => \@conds },
    _renderer => $self->{renderer},
  );
}

sub not {
  my ($self, $cond) = @_;
  SQL::Wizard::Expr::Raw->new(
    sql       => 'NOT',
    bind      => [],
    _not      => $cond,
    _renderer => $self->{renderer},
  );
}

## CTEs

sub with {
  my ($self, @args) = @_;
  my @ctes;
  while (@args) {
    my $name  = shift @args;
    my $query = shift @args;
    push @ctes, { name => $name, query => $query };
  }
  SQL::Wizard::Expr::CTE->new(
    ctes      => \@ctes,
    _renderer => $self->{renderer},
  );
}

sub with_recursive {
  my ($self, @args) = @_;
  my @ctes;
  while (@args) {
    my $name  = shift @args;
    my $query = shift @args;
    push @ctes, { name => $name, query => $query };
  }
  SQL::Wizard::Expr::CTE->new(
    ctes      => \@ctes,
    recursive => 1,
    _renderer => $self->{renderer},
  );
}

1;
