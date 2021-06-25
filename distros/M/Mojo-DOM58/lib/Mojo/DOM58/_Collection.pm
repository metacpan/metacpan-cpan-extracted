package Mojo::DOM58::_Collection;

# This file is part of Mojo::DOM58 which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for Mojo::DOM58 for full license details.

use strict;
use warnings;
use Carp 'croak';
use List::Util;
use Scalar::Util 'blessed';
use re ();

use constant REDUCE => ($] >= 5.008009 ? \&List::Util::reduce : \&_reduce);
use constant HAS_IS_REGEXP => !!($] >= 5.010000);

# Role support requires Role::Tiny 2.000001+
use constant ROLES =>
  !!(eval { require Role::Tiny; Role::Tiny->VERSION('2.000001'); 1 });

our $VERSION = '3.001';

sub new {
  my $class = shift;
  return bless [@_], ref $class || $class;
}

sub TO_JSON { [@{shift()}] }

sub compact {
  my $self = shift;
  return $self->new(grep { defined && (ref || length) } @$self);
}

sub each {
  my ($self, $cb) = @_;
  return @$self unless $cb;
  my $i = 1;
  $_->$cb($i++) for @$self;
  return $self;
}

sub first {
  my ($self, $cb) = (shift, shift);
  return $self->[0] unless $cb;
  return List::Util::first { $_ =~ $cb } @$self if HAS_IS_REGEXP ? re::is_regexp($cb) : ref $cb eq 'Regexp';
  return List::Util::first { $_->$cb(@_) } @$self;
}

sub flatten { $_[0]->new(_flatten(@{$_[0]})) }

sub grep {
  my ($self, $cb) = (shift, shift);
  return $self->new(grep { $_ =~ $cb } @$self) if HAS_IS_REGEXP ? re::is_regexp($cb) : ref $cb eq 'Regexp';
  return $self->new(grep { $_->$cb(@_) } @$self);
}

sub head {
  my ($self, $size) = @_;
  return $self->new(@$self) if $size > @$self;
  return $self->new(@$self[0 .. ($size - 1)]) if $size >= 0;
  return $self->new(@$self[0 .. ($#$self + $size)]);
}

sub join {
  join +(defined($_[1]) ? $_[1] : ''), map {"$_"} @{$_[0]};
}

sub last { shift->[-1] }

sub map {
  my ($self, $cb) = (shift, shift);
  return $self->new(map { $_->$cb(@_) } @$self);
}

sub reduce {
  my $self = shift;
  @_ = (@_, @$self);
  goto &{REDUCE()};
}

sub reverse { $_[0]->new(reverse @{$_[0]}) }

sub shuffle { $_[0]->new(List::Util::shuffle @{$_[0]}) }

sub size { scalar @{$_[0]} }

sub slice {
  my $self = shift;
  return $self->new(@$self[@_]);
}

sub sort {
  my ($self, $cb) = @_;

  return $self->new(sort @$self) unless $cb;

  my $caller = caller;
  no strict 'refs';
  my @sorted = sort {
    local (*{"${caller}::a"}, *{"${caller}::b"}) = (\$a, \$b);
    $a->$cb($b);
  } @$self;
  return $self->new(@sorted);
}

sub tail {
  my ($self, $size) = @_;
  return $self->new(@$self) if $size > @$self;
  return $self->new(@$self[($#$self - ($size - 1)) .. $#$self]) if $size >= 0;
  return $self->new(@$self[(0 - $size) .. $#$self]);
}

sub tap {
  my ($self, $cb) = (shift, shift);
  $_->$cb(@_) for $self;
  return $self;
}

sub to_array { [@{shift()}] }

sub uniq {
  my ($self, $cb) = (shift, shift);
  my %seen;
  return $self->new(grep { my $r = $_->$cb(@_); !$seen{defined $r ? $r : ''}++ } @$self) if $cb;
  return $self->new(grep { !$seen{defined $_ ? $_ : ''}++ } @$self);
}

sub with_roles {
  croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
  my ($self, @roles) = @_;
  
  return Role::Tiny->create_class_with_roles($self,
    map { /^\+(.+)$/ ? "${self}::Role::$1" : $_ } @roles)
    unless my $class = blessed $self;
  
  return Role::Tiny->apply_roles_to_object($self,
    map { /^\+(.+)$/ ? "${class}::Role::$1" : $_ } @roles);
}

sub _flatten {
  map { _ref($_) ? _flatten(@$_) : $_ } @_;
}

# For perl < 5.8.9
sub _reduce (&@) {
  my $code = shift;

  return shift unless @_ > 1;

  my $caller = caller;

  no strict 'refs';

  local (*{"${caller}::a"}, *{"${caller}::b"}) = (\my $x, \my $y);

  $x = shift;
  foreach my $e (@_) {
    $y = $e;
    $x = $code->();
  }

  $x;
}

sub _ref { ref $_[0] eq 'ARRAY' || blessed $_[0] && $_[0]->isa(__PACKAGE__) }

1;

=for Pod::Coverage *EVERYTHING*

=cut
