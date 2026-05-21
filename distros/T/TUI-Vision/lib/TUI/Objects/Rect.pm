package TUI::Objects::Rect;
# ABSTRACT: defines the class TRect

use 5.010;
use strict;
use warnings;

use List::Util qw( min max );
use TUI::Objects::Point;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TRect
  new_TRect
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  :is
  :types
);

sub TRect() { __PACKAGE__ }
sub new_TRect { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = ( 
    a => sub { TPoint->new() },
    b => sub { TPoint->new() },
  );
}

# This method accepts a variable number of arguments:
#
# If four arguments I<(ax, ay, bx, by)> are provided, it creates two I<TPoint> 
# objects for points I<a> and I<b> with the specified coordinates.
#
# If two arguments I<(a, b)> are provided, it sets points I<a> and I<b> to the
# provided I<TPoint> objects.
#
# If no or any other number of arguments are provided, it initializes points 
# I<a> and I<b> with new I<TPoint> objects with default values.
sub new {    # \$obj (%args)
  my ( $class, $self );
  if ( @_ < 4 ) {
    state $sig = signature(
      method => 1,
      named  => [],
    );
    ( $class ) = $sig->( @_ );
    $self = {
      a => $HAS{a}->(),
      b => $HAS{b}->(),
    };
  }
  elsif ( @_ < 8 ) {
    state $sig = signature(
      method => 1,
      named  => [
        a => HashLike,
        b => HashLike,
      ],
    );
    ( $class, my $args ) = $sig->( @_ );
    $self = {
      a => TPoint->new( x => $args->{a}{x}, y => $args->{a}{y} ),
      b => TPoint->new( x => $args->{b}{x}, y => $args->{b}{y} ),
    };
  } 
  else {
    state $sig = signature(
      method => 1,
      named  => [
        ax => Int,
        ay => Int,
        bx => Int,
        by => Int,
      ],
    );
    ( $class, my $args ) = $sig->( @_ );
    $self = {
      a => TPoint->new( x => $args->{ax}, y => $args->{ay} ),
      b => TPoint->new( x => $args->{bx}, y => $args->{by} ),
    };
  }
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub from {    # $obj ($ax, $ay, $bx, $by)
  state $sig = signature(
    method => 1,
    pos    => [Int, Int, Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( ax => $args[0], ay => $args[1], bx => $args[2], 
    by => $args[3] );
}

sub assign {    # void ($ax, $ay, $bx, $by)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Int, Int],
  );
  my ( $self, $ax, $ay, $bx, $by ) = $sig->( @_ );
  $self->{a}{x} = $ax;
  $self->{a}{y} = $ay;
  $self->{b}{x} = $bx;
  $self->{b}{y} = $by;
  return;
} #/ sub assign

sub clone {    # $rect ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $class = ref $self;
  return $class->new(
    a => $self->{a}->clone(),
    b => $self->{b}->clone(),
  );
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

sub move {    # void ($aDX, $aDY)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aDX, $aDY ) = $sig->( @_ );
  $self->{a}{x} += $aDX;
  $self->{a}{y} += $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub grow {    # void ($aDX, $aDY)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aDX, $aDY ) = $sig->( @_ );
  $self->{a}{x} -= $aDX;
  $self->{a}{y} -= $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub intersect {    # void ($r)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $r ) = $sig->( @_ );
  $self->{a}{x} = max( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = max( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = min( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = min( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub Union {    # void ($r)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $r ) = $sig->( @_ );
  $self->{a}{x} = min( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = min( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = max( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = max( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub contains {    # $bool ($p)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $p ) = $sig->( @_ );
  return
       $p->{x} >= $self->{a}{x}
    && $p->{x} <  $self->{b}{x}
    && $p->{y} >= $self->{a}{y}
    && $p->{y} <  $self->{b}{y};
}

sub equal {    # $bool ($r, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return
       $one->{a}{x} == $two->{a}{x}
    && $one->{a}{y} == $two->{a}{y}
    && $one->{b}{x} == $two->{b}{x}
    && $one->{b}{y} == $two->{b}{y};
}

sub not_equal {    # $bool ($r, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return !equal( $one, $two );
}

sub isEmpty {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{a}{x} >= $self->{b}{x} 
      || $self->{a}{y} >= $self->{b}{y};
}

use overload
  '==' => \&equal,
  '!=' => \&not_equal,
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
        assert ( is_Object $_[1] );
        $_[0]->{$field} = $_[1]->clone();
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

TUI::Objects::Rect - rectangular area defined by two points

=head1 HIERARCHY

  TRect (value type)
    composed of two TPoint objects

=head1 SYNOPSIS

  use TUI::Objects;

  my $r1 = TRect->new( ax => 0, ay => 0, bx => 80, by => 25 );
  my $r2 = TRect->new(
    a => TPoint->new( x => 10, y => 5 ),
    b => TPoint->new( x => 40, y => 15 ),
  );

  my $copy = $r1->clone();
  $copy->move( 2, 1 );
  $copy->grow( 1, 1 );

  if ( $r1 == $r2 ) {
    ...
  }

=head1 DESCRIPTION

C<TRect> represents a rectangular area defined by two corner points. The
attribute C<a> specifies the upper-left corner and C<b> specifies the
lower-right corner of the rectangle.

C<TRect> is a lightweight value type and is not derived from C<TObject>. It is
used throughout TUI::Vision to describe screen locations and sizes of views,
dialogs, and controls.

The class provides a set of geometric operations such as moving, resizing,
intersection, and containment testing. Rectangles can also be compared for
equality using operator overloading.

=head2 Commonly Used Features

Most code constructs rectangles directly with C<TRect-E<gt>new> using
coordinate arguments, then passes them into view and dialog constructors.
For incremental layout changes, C<move> and C<grow> are the common operations,
and C<clone> is useful when you need a temporary variant without mutating the
original bounds object.

=head1 CONSTRUCTOR

=head2 new

  my $rect = TRect->new();

  my $rect = TRect->new(
    a => $pointA,
    b => $pointB
  );

  my $rect = TRect->new(
    ax => $ax,
    ay => $ay,
    bx => $bx,
    by => $by
  );

Creates a new rectangle.

When point coordinates are supplied, the constructor creates internal
C<TPoint> objects automatically.

=over

=item a

Upper-left corner as a C<TPoint>.

=item b

Lower-right corner as a C<TPoint>.

=item ax, ay, bx, by

Integer coordinates used to initialize the corner points.

=back

=head2 new_TRect

  my $rect = new_TRect($ax, $ay, $bx, $by);

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 ATTRIBUTES

The following attributes define the rectangle geometry.

=over

=item a

Upper-left corner of the rectangle (I<TPoint>).

=item b

Lower-right corner of the rectangle (I<TPoint>).

=back

=head1 METHODS

=head2 assign

  $rect->assign($ax, $ay, $bx, $by);

Sets the coordinates of the rectangle corners.

=head2 clone

  my $copy = $rect->clone();

Creates and returns a copy of the rectangle.

=head2 contains

  my $bool = $rect->contains($point);

Returns true if the specified point lies within the rectangle.

=head2 dump

  my $string = $rect->dump();

Returns a string representation of the rectangle for debugging.

=head2 equal

  my $bool = $rect->equal($other, | $swap);

Implements the C<==> operator for rectangle comparison.

=head2 grow

  $rect->grow($dx, $dy);

Expands or contracts the rectangle by adjusting its corner points.

=head2 intersect

  $rect->intersect($other);

Modifies the rectangle to become the intersection of itself and another
rectangle.

=head2 isEmpty

  my $bool = $rect->isEmpty();

Returns true if the rectangle has zero area.

=head2 move

  $rect->move($dx, $dy);

Moves the rectangle by adding offsets to both corner points.

=head2 not_equal

  my $bool = $rect->not_equal($other, | $swap);

Implements the C<!=> operator for rectangle comparison.

=head2 union

  $rect->union($other);

Expands the rectangle so that it encompasses both rectangles.

=head1 OPERATOR OVERLOADING

C<TRect> supports comparison operators through Perl operator overloading.

=over

=item *

C<==> maps to C<equal>

=item *

C<!=> maps to C<not_equal>

=back

=head1 SEE ALSO

L<TUI::Objects::Point>,
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
