package Object::Array::Plugin::Builtins;

use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [
    qw(
       size length
       element elem
       slice
       elements elems
       clear
       pop
       push
       shift
       unshift
       exists
       delete
       splice
       map
       grep
       join
     ),
  ],
};

=head1 NAME

Object::Array::Plugin::Builtins

=head1 SYNOPSIS

See L<Object::Array>.

Provides analogues to Perl's built-in array operations.

=head1 METHODS

=head2 C<< size >>

=head2 C<< length >>

Returns the number of elements in the array.

C<< size >> and C<< length >> are synonyms.

=head2 C<< element >>

=head2 C<< elem >>

  print $array->elem(0);
  print $array->[0];

Get a single element's value.

  $array->elem(1 => "hello");
  $array->[1] = "hello";

Set a single element's value.

C<< element >> and C<< elem >> are synonyms.

=head2 C<< slice >>

  print for $array->slice([ 0, 1, 2 ]);
  print for @{$array}[0,1,2];

Get multiple values.

  $array->slice([ 0, 1, 2 ] => [ qw(a b c) ]);
  @{$array}[0,1,2] = qw(a b c);

Set multiple values.

=head2 C<< elements >>

=head2 C<< elems >>

Shortcut for all values in the array.

C<< elements >> and C<< elems >> are synonyms.

NOTE: Using methods in a for/map/etc. will not do aliasing
via $_.  Use array dereferencing if you need to do this, e.g.

  $_++ for @{$array};

=head2 C<< clear >>

Erase the array.  The following all leave the array empty:

  $array->size(0);
  $array->clear;
  @{ $array } = ();

=head2 C<< push >>

=head2 C<< pop >>

=head2 C<< shift >>

=head2 C<< unshift >>

=head2 C<< exists >>

=head2 C<< delete >>

=head2 C<< splice >>

=head2 C<< map >>

=head2 C<< grep >>

=head2 C<< join >>

As the builtin array operations of the same names.

Note that since map and grep are called as methods, you must
use C<<sub { }>> (no bare blocks).

=cut

sub map {
  my ($self, $code) = @_;
  return $self->_array(map { $code->() } @{ $self });
}

sub grep {
  my ($self, $code) = @_;
  return $self->_array(grep { $code->() } @{ $self });
}

sub join {
  my $self = shift;
  return join(shift, @{ $self });
}

sub size {
  my $self = shift;
  if (@_) {
    $#{ $self->_real } = shift(@_) - 1;
  }
  return scalar @{ $self->_real };
}

*length = \*size;

sub elem {
  my $self = shift;
  unless (@_) {
    require Carp;
    Carp::croak("must specify index for element lookup");
  }

  my $idx  = shift || 0;

  if (@_) {
    $self->_real->[$idx] = shift;
  }
  return $self->_real->[$idx];
}
*element = \&elem;

sub slice {
  my $self = shift;
  my $idx  = shift;
  unless ($idx and ref($idx) eq 'ARRAY') {
    require Carp;
    Carp::croak("must specify arrayref of indices for slice");
  }

  # since tying can deal with this, might as well let it
  if (@_) {
    return $self->_array(@{ $self }[ @$idx ] = @{ +shift });
  } else {
    return $self->_array(@{ $self }[ @$idx ]);
  }
}

sub elems   { @{ shift->_real } }

*elements = \&elems;

sub clear   { @{ shift->_real } = () }

sub pop     { pop @{ shift->_real } }

sub push    { push @{ shift->_real }, @_ }

sub unshift { unshift @{ shift->_real }, @_ }

sub exists  { exists shift->_real->[shift] }

sub delete  { delete shift->_real->[shift] }

sub splice  { splice @{ shift->_real }, @_ }

# shift goes last to avoid annoying warnings
sub shift   { shift @{ shift->_real } }

1;
