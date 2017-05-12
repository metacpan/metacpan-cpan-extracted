use strict;
use warnings;

package Pad::Tie::Plugin::List;

use base 'Pad::Tie::Plugin';

sub provides { 'list' }

sub list {
  my ($plugin, $ctx, $self, $args) = @_;
  # XXX seriously, refactor this
  my $class = ref($plugin) || $plugin;

  $args = $plugin->canon_args($args);
  
  # XXX seriously, refactor this too
  for my $method (keys %$args) {
    tie @{ $ctx->{'@' . $args->{$method}} = [] }, $class, $self, $method;
  }
}

sub INV         () { 0 }
sub METHOD      () { 1 }
sub FETCH_CACHE () { 2 }
sub STORE_COUNT () { 3 }
sub STORE_CACHE () { 4 }

# XXX this looks familiar too
sub TIEARRAY {
  my ($class, $inv, $method) = @_;
  bless [ $inv, $method ] => $class;
}

BEGIN {
  for my $unimp (qw(STORESIZE EXISTS DELETE PUSH POP SHIFT UNSHIFT
    SPLICE)) {
    no strict 'refs';
    *$unimp = sub { Carp::croak "invalid operation for list method: $unimp" };
  }
}

sub __fetch {
  my $self = shift;
  my ($inv, $method) = @$self;
  return @{ $self->[FETCH_CACHE] } = $inv->$method;
}
  
sub FETCH {
  $_[0]->__fetch;
  return $_[0]->[FETCH_CACHE]->[$_[1]];
}

sub FETCHSIZE {
  my $self = shift;
  $self->[STORE_COUNT] = undef;
  return $self->__fetch;
}

sub STORE {
  my $self = shift;
  Carp::croak "do not assign to individual list elements"
    unless defined $self->[STORE_COUNT];
  push @{ $self->[STORE_CACHE] }, $_[1];
  if (--$self->[STORE_COUNT] < 1) {
    my ($inv, $method) = @$self;
    #warn "calling $inv->$method with @{ $self->[STORE_CACHE] }\n";
    $inv->$method(@{ $self->[STORE_CACHE] });
    $self->[STORE_CACHE] = [];
    $self->[STORE_COUNT] = undef;
  } 
}

sub CLEAR {
  undef $_[0]->[$_] for FETCH_CACHE, STORE_COUNT, STORE_CACHE;
}

sub EXTEND {
  $_[0]->[FETCH_CACHE] = undef;
  $_[0]->[STORE_COUNT] = $_[1];
  $_[0]->[STORE_CACHE] = [];
}

1;
