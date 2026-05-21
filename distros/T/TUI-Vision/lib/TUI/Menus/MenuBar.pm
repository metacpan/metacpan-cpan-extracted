package TUI::Menus::MenuBar;
# ABSTRACT: TMenuBar object manages the menu bar across the top of the app.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuBar
  new_TMenuBar
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Util qw( cstrlen );
use TUI::Menus::Menu;
use TUI::Menus::MenuView;
use TUI::Menus::SubMenu;
use TUI::Views::DrawBuffer;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  gfGrowHiX
  ofPreProcess
);

sub TMenuBar() { __PACKAGE__ }
sub name() { 'TMenuBar' }
sub new_TMenuBar { __PACKAGE__->from(@_) }

extends TMenuView;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds => Object,
      menu   => Maybe[Object], { alias => 'aMenu' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  my $menu = $args->{menu};
  $self->{menu} = ref $menu && $menu->isa(TSubMenu) 
    ? TMenu->new( items => $menu )
    : $menu;
  $self->{growMode} = gfGrowHiX;
  $self->{options} |= ofPreProcess;
  return;
}

sub from {    # $obj ($bounds, $aMenu)
  state $sig = signature(
    method => 1,
    pos => [Object, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], menu => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  undef $self->{menu};
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $color;
  my ( $x, $l );
  my $p;
  my $b = TDrawBuffer->new();

  my $cNormal       = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  $b->moveChar( 0, ' ', $cNormal, $self->{size}{x} );
  if ( $self->{menu} ) {
    $x = 1;
    $p = $self->{menu}{items};
    while ( $p ) {
      if ( $p->{name} ) {
        $l = cstrlen( $p->{name} );
        if ( $x + $l < $self->{size}{x} ) {
          no warnings 'uninitialized';
          if ( $p->{disabled} ) {
            $color = ( $p == $self->{current} ) 
              ? $cSelDisabled 
              : $cNormDisabled;
          }
          else {
            $color = ( $p == $self->{current} ) 
              ? $cSelect 
              : $cNormal;
          }
          $b->moveChar( $x, ' ', $color, 1 );
          $b->moveCStr( $x + 1, $p->{name}, $color );
          $b->moveChar( $x + $l + 1, ' ', $color, 1 );
        } #/ if ( $x + $l < $self->...)
        $x += $l + 2;
      } #/ if ( $p->{name} )
      $p = $p->{next};
    } #/ while ( $p )
  } #/ if ( $self->{menu} )
  $self->writeBuf( 0, 0, $self->{size}{x}, 1, $b );
} #/ sub draw

sub getItemRect {    # $rect ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $r = TRect->new( ax => 1, ay => 0, bx => 1, by => 1 );
  my $p = $self->{menu}{items};
  while ( 1 ) {
    $r->{a}{x} = $r->{b}{x};
    if ( $p->{name} ) {
      $r->{b}{x} += cstrlen( $p->{name} ) + 2;
    }
    {
      no warnings 'uninitialized';
      return $r
        if $p == $item;
    }
    $p = $p->{next};
  }
}

1

__END__

=pod

=head1 NAME

TUI::Menus::MenuBar - manages the menu bar at the top of the application

=head1 HIERARCHY

  TObject
    TView
      TMenuView
        TMenuBar

=head1 SYNOPSIS

  use TUI::Menus;

  my $menuBar = new_TMenuBar($bounds, $menu);

=head1 DESCRIPTION

C<TMenuBar> implements the menu bar displayed at the top of a TUI::Vision
application. In this Perl implementation, menu structures are created using
a declarative, expression-based style rather than explicit builder calls.

Menus are constructed by combining submenu and menu item objects using the
overloaded C<+> operator. This allows entire menu trees to be expressed as a
single expression that is passed directly to the menu bar constructor.

The resulting structure closely mirrors the logical menu hierarchy while
remaining compact and readable. Once created, the menu bar handles drawing,
keyboard navigation, and mouse interaction automatically.

=head1 CONSTRUCTOR

=head2 new

  my $menuBar = TMenuBar->new(
    bounds => $bounds,
    menu   => $menu
  );

Creates a new menu bar.

=over

=item bounds

Bounding rectangle of the menu bar (I<TRect>).

=item menu

Root menu structure defining the contents of the menu bar (I<TMenu> or undef).

=back

=head2 new_TMenuBar

  my $menuBar = new_TMenuBar($bounds, $menu);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 draw

  $menuBar->draw();

Draws the menu bar and highlights the currently selected menu item.

=head2 getItemRect

  my $rect = $menuBar->getItemRect($item | undef);

Returns the screen rectangle occupied by the specified menu item. This method
is used internally to determine whether a mouse click occurred on a particular
menu entry.

=head1 EXAMPLE

The following example shows how a menu bar can be constructed using chained
menu and submenu objects.

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return new_TMenuBar(
      $r,
      new_TSubMenu( '~F~ile', hcNoContext )
        + new_TMenuItem( '~O~pen...', cmFileOpen, kbF3, hcNoContext, 'F3' )
        + new_TMenuItem( '~S~ave as...', cmFileSave, hcNoContext )
        + newLine
        + new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' )
      + new_TSubMenu( '~H~elp', hcNoContext )
        + new_TMenuItem( '~A~bout', cmAbout, hcNoContext )
    );
  }

=head1 SEE ALSO

L<TUI::Menus::Menu>,
L<TUI::Menus::MenuBox>,
L<TUI::Menus::MenuView>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
