package SQL::Wizard::Expr::Compound;

use strict;
use warnings;
use Storable qw(dclone);
use parent 'SQL::Wizard::Expr';

sub new {
  my ($class, %args) = @_;
  # args: queries => [ { type => undef|'UNION'|..., query => $select }, ... ]
  $class->SUPER::new(%args);
}

# Chain more compounds

sub union {
  my ($self, $other) = @_;
  my $clone = dclone($self);
  push @{$clone->{queries}}, { type => 'UNION', query => $other };
  $clone;
}

sub union_all {
  my ($self, $other) = @_;
  my $clone = dclone($self);
  push @{$clone->{queries}}, { type => 'UNION ALL', query => $other };
  $clone;
}

sub intersect {
  my ($self, $other) = @_;
  my $clone = dclone($self);
  push @{$clone->{queries}}, { type => 'INTERSECT', query => $other };
  $clone;
}

sub except {
  my ($self, $other) = @_;
  my $clone = dclone($self);
  push @{$clone->{queries}}, { type => 'EXCEPT', query => $other };
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

1;
