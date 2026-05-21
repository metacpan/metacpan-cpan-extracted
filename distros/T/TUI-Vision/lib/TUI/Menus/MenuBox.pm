package TUI::Menus::MenuBox;
# ABSTRACT: Pull-down or pop-up menu box

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuBox
  new_TMenuBox
);

use List::Util qw( max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Menus::MenuView;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  sfShadow
  ofPreProcess
);
use TUI::Views::DrawBuffer;

sub TMenuBox() { __PACKAGE__ }
sub name { 'TMenuBox' }
sub new_TMenuBox { __PACKAGE__->from(@_) }

extends TMenuView;

# declare global variables
our $frameChars =
  # for UnitedStates code page
  " \332\304\277  \300\304\331  \263 \263  \303\304\264 ";

# predeclare private methods
my (
  $getRect,
  $frameLine,
  $drawLine,
);

sub _getRect { goto &$getRect }
$getRect = sub {    # $rect ($bounds, $aMenu|undef)
  my ( $class, $bounds, $aMenu ) = @_;
  assert ( @_ == 3 );
  assert ( is_Str $class );
  assert ( is_Object $bounds );
  assert ( !defined $aMenu or is_Object $aMenu );
  my $w = 10;
  my $h = 2;
  if ( $aMenu ) {
    for ( my $p = $aMenu->{items} ; $p ; $p = $p->{next} ) {
      if ( $p->{name} ) {
        my $l = length( $p->{name} ) + 6;
        if ( !$p->{command} ) {
          $l += 3
        }
        elsif ( $p->{param} ) {
          $l += length( $p->{param} ) + 2
        }
        $w = max( $l, $w );
      }
      $h++;
    }
  } #/ if ( $aMenu )

  my $r = $bounds->clone();

  if ( $r->{a}{x} + $w < $r->{b}{x} ) {
    $r->{b}{x} = $r->{a}{x} + $w;
  }
  else {
    $r->{a}{x} = $r->{b}{x} - $w;
  }

  if ( $r->{a}{y} + $h < $r->{b}{y} ) {
    $r->{b}{y} = $r->{a}{y} + $h;
  }
  else {
    $r->{a}{y} = $r->{b}{y} - $h;
  }

  return $r;
}; #/ sub $getRect

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      menu       => Maybe[Object], { alias => 'aMenu' },
      parentMenu => Maybe[Object], { alias => 'aParentMenu' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => $class->$getRect( $args1->{bounds}, $args1->{menu} ),
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{state} |= sfShadow;
  $self->{options} |= ofPreProcess;
  return;
}

sub from {    # $obj ($bounds, $aMenu|undef, $aParent|undef);
  state $sig = signature(
    method => 1,
    pos => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], menu => $args[1], 
    parentMenu => $args[2]);
}

my ( $cNormal, $color );

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();

  $cNormal = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  my $y             = 0;
  $color = $cNormal;
  $self->$frameLine( $b, 0 );
  $self->writeBuf( 0, $y++, $self->{size}{x}, 1, $b );

  if ( $self->{menu} ) {
    for ( my $p = $self->{menu}{items} ; $p ; $p = $p->{next} ) {
      $color = $cNormal;
      if ( !$p->{name} ) {
        $self->$frameLine( $b, 15 );
      }
      else {
        {
          no warnings 'uninitialized';
          if ( $p->{disabled} ) {
            $color = ( $p == $self->{current} ) 
              ? $cSelDisabled 
              : $cNormDisabled;
          }
          elsif ( $p == $self->{current} ) {
            $color = $cSelect;
          }
        }
        $self->$frameLine( $b, 10 );
        $b->moveCStr( 3, $p->{name}, $color );
        if ( !$p->{command} ) {
          $b->putChar( $self->{size}{x} - 4, 16 );
        }
        elsif ( $p->{param} ) {
          $b->moveStr( $self->{size}{x} - 3 - length( $p->{param} ), 
            $p->{param}, $color );
        }
      } #/ else [ if ( !$p->{name} ) ]
      $self->writeBuf( 0, $y++, $self->{size}{x}, 1, $b );
    } #/ for ( my $p = $self->{menu...})
  } #/ if ( $self->{menu} )
  $color = $cNormal;
  $self->$frameLine( $b, 5 );
  $self->writeBuf( 0, $y, $self->{size}{x}, 1, $b );
  return;
} #/ sub draw

sub getItemRect {    # $rect ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $y = 1;
  my $p = $self->{menu}{items};

  {
    no warnings 'uninitialized';
    while ( $p != $item ) {
      $y++;
      $p = $p->{next};
    }
  }
  return TRect->new(
    ax => 2,
    ay => $y,
    bx => $self->{size}{x} - 2,
    by => $y + 1,
  );
} #/ sub getItemRect

$frameLine = sub {    # void ($b, $n)
  my ( $self, $b, $n ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $b );
  assert ( is_Int $n );
  $b->moveBuf(
    0, [ unpack 'W*' => substr( $frameChars, $n, 2 ) ], $cNormal, 2 );
  $b->moveChar(
    2, substr( $frameChars, $n + 2, 1 ), $color, $self->{size}{x} - 4 );
  $b->moveBuf( $self->{size}{x} - 2,
    [ unpack 'W*' => substr( $frameChars, $n + 3, 2 ) ], $cNormal, 2 );
  return;
};

$drawLine = sub {    # void ($b)
  my ( $self, $b ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashLike $b );
  ...
};

1

__END__

=pod

=head1 NAME

TUI::Menus::MenuBox - pull-down or pop-up menu box

=head1 HIERARCHY

  TObject
    TView
      TMenuView
        TMenuBox

=head1 SYNOPSIS

  use TUI::Menus;
  use TUI::Objects;

  my $bounds = TRect->new( ax => 10, ay => 5, bx => 40, by => 12 );

  my $menu = new_TMenu(
    new_TMenuItem( '~A~dd Watch',        1, 0 ),
    new_TMenuItem( '~D~elete Watch',     2, 0 ),
    new_TMenuItem( '~E~dit Watch...',    3, 0 ),
    new_TMenuItem( '~R~emove all',       4, 0 ),
  );

  my $menuBox = TMenuBox->new(
    bounds     => $bounds,
    menu       => $menu,
    parentMenu => undef,
  );
  my $cmd = $desktop->execView( $menuBox );   # returns selected command

=head1 DESCRIPTION

C<TMenuBox> implements a menu box that displays the contents of a menu either
as a pull-down menu originating from a menu bar or as a standalone pop-up
menu.

Menu boxes handle drawing, keyboard navigation, and mouse interaction for menu
items. They are most commonly created indirectly as part of a menu bar, but may
also be instantiated explicitly to present a temporary selection menu.

For standard pull-down menus, the parent menu view is typically the menu bar.
For standalone menu boxes, the parent menu may be omitted.

=head2 Commonly Used Features

In most applications C<TMenuBox> is never referenced directly, because
pull-down menus are built automatically through the menu bar. The practical
use case is a standalone pop-up: construct the box with C<new_TMenuBox>,
passing the desired bounding rectangle, a menu built from C<new_TMenu> and
C<new_TMenuItem> calls, and C<undef> as the parent. Pass the resulting object
to C<< $desktop->execView >>, which returns the command constant of the
selected item.

=head1 VARIABLES

The following global variable defines the frame characters used by
C<TMenuView>.

=head2 $frameChars

Character sequence used to draw menu frames and borders.

=head1 CONSTRUCTOR

=head2 new

  my $menuBox = TMenuBox->new(
    bounds     => $bounds,
    menu       => $menu,
    parentMenu => $parentMenu
  );

Creates a new menu box.

=over

=item bounds

Bounding rectangle of the menu box (I<TRect>).

=item menu

Menu structure defining the items displayed by the menu box (I<TMenu>).

=item parentMenu

Optional parent menu view (I<TMenuView>). This parameter may be omitted for
standalone menu boxes.

=back

=head2 new_TMenuBox

  my $menuBox = new_TMenuBox($bounds, $menu, | $parentMenu);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 draw

  $menuBox->draw();

Draws the menu box and its contents, highlighting the currently focused item.

=head2 getItemRect

  my $rect = $menuBox->getItemRect($item | undef);

Returns the screen rectangle occupied by the specified menu item. This method
is used internally to determine whether a mouse click occurred on a particular
menu entry.

=head1 SEE ALSO

L<TUI::Menus::MenuBar>,
L<TUI::Menus::MenuView>,
L<TUI::Menus::MenuItem>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
