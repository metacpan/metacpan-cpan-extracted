package TUI::Objects::Point;
# ABSTRACT: defines the class TPoint

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPoint
  new_TPoint
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  :is
  :types
);

sub TPoint() { __PACKAGE__ }
sub new_TPoint { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = ( 
    x => sub { 0 },
    y => sub { 0 },
  );
}

sub new {    # \$obj (%args)
  state $sig = signature(
    method => 1,
    named  => [
      x => Int, { optional => 1 },
      y => Int, { optional => 1 },
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my $self = {
    x => $args->{x} // $HAS{x}->(),
    y => $args->{y} // $HAS{y}->(),
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $obj ($x, $y)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( x => $args[0], y => $args[1] );
}

sub clone {    # $p ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $class = ref $self || $self;
  return $class->new( %$self );
}

sub dump {    # $str ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  return Data::Dumper::Dumper $self;
}

sub add {    # $p ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return TPoint->new( x => $one->{x} + $two->{x}, y => $one->{y} + $two->{y} );
}

sub subtract {    # $p ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  ( $one, $two ) = ( $two, $one ) if $swap;
  return TPoint->new( x => $one->{x} - $two->{x}, y => $one->{y} - $two->{y} );
}

sub equal {    # $bool ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return $one->{x} == $two->{x} && $one->{y} == $two->{y};
}

sub not_equal {    # $bool ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return !equal( $one, $two );
}

sub add_assign {    # $self ($adder, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [HashLike, Bool, { optional => 1 }],
  );
  my ( $self, $adder, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->{x} += $adder->{x};
  $self->{y} += $adder->{y};
  return $self;
}

sub subtract_assign {    # $self ($subber, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [HashLike, Bool, { optional => 1 }],
  );
  my ( $self, $subber, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->{x} -= $subber->{x};
  $self->{y} -= $subber->{y};
  return $self;
}

use overload
  '+'  => \&add,
  '-'  => \&subtract,
  '==' => \&equal,
  '!=' => \&not_equal,
  '+=' => \&add_assign,
  '-=' => \&subtract_assign,
  fallback => 1;

my $mk_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( is_Object $_[0] );
      if ( @_ > 1 ) {
        assert ( is_Int $_[1] );
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %HAS)
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1

__END__

=pod

=head1 NAME

TUI::Objects::Point - two-dimensional point value type

=head1 HIERARCHY

  TPoint (value type)
    used by TRect and view-related classes

=head1 SYNOPSIS

  use TUI::Objects;

  my $p1 = new_TPoint(10, 5);
  my $p2 = new_TPoint(3, 2);

  my $p3 = $p1 + $p2;
  my $p4 = $p1 - $p2;

  if ( $p3 == $p4 ) {
    ...
  }

=head1 DESCRIPTION

C<TPoint> represents a two-dimensional point with integer coordinates. It is a
lightweight value type and is not derived from C<TObject>. Instances are
typically used to represent positions, sizes, or offsets within the Turbo
Vision coordinate system.

The class supports arithmetic and comparison operators through Perl operator
overloading, allowing points to be combined and compared naturally.

=head1 CONSTRUCTOR

=head2 new

  my $point = TPoint->new(
    x => $x,
    y => $y
  );

Creates a new point object.

=over

=item x

Horizontal coordinate (I<Int>).

=item y

Vertical coordinate (I<Int>).

=back

=head2 new_TPoint

  my $point = new_TPoint($x, $y);

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 ATTRIBUTES

The following attributes define the coordinates of the point.

=over

=item x

Horizontal coordinate (I<Int>).

=item y

Vertical coordinate (I<Int>).

=back

=head1 METHODS

=head2 add

  my $p = $point->add($a, $b, | $swap);

Returns the sum of two points.

=head2 add_assign

  $point->add_assign($other, | $swap);

Adds another point to this point in place.

=head2 clone

  my $copy = $point->clone();

Creates and returns a copy of the point.

=head2 dump

  my $string = $point->dump();

Returns a string representation of the point for debugging purposes.

=head2 equal

  my $bool = $point->equal($a, $b, | $swap);

Returns true if two points have equal coordinates.

=head2 not_equal

  my $bool = $point->not_equal($a, $b, | $swap);

Returns true if two points differ in at least one coordinate.

=head2 subtract

  my $p = $point->subtract($a, $b, | $swap);

Returns the difference between two points.

=head2 subtract_assign

  $point->subtract_assign($other, | $swap);

Subtracts another point from this point in place.

=head1 OPERATOR OVERLOADING

C<TPoint> supports arithmetic and comparison operations through Perl operator
overloading. The following operators are implemented and mapped directly to
their corresponding methods:

=over

=item *

C<+> and C<+=> for point addition

=item *

C<-> and C<-=> for point subtraction

=item *

C<==> and C<!=> for equality and inequality comparison

=back

Operator overloading allows point objects to be combined and compared using
natural arithmetic expressions.

=head1 SEE ALSO

L<TUI::Objects::Rect>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
