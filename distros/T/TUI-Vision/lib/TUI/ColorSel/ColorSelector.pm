package TUI::ColorSel::ColorSelector;
# ABSTRACT: interactive color selection view

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorSelector
  new_TColorSelector
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  kbLeft
  kbRight
  kbUp
  kbDown
);
use TUI::Drivers::Util qw( ctrlToArrow );
use TUI::ColorSel::Const qw(
  :cmXXXX
  :csXXXX
);
use TUI::Views::Const qw( 
  ofSelectable
  ofFirstClick
  ofFramed
);
use TUI::Views::DrawBuffer;
use TUI::Views::View;
use TUI::Views::Util qw( message );

sub TColorSelector() { __PACKAGE__ }
sub name() { 'TColorSelector' }
sub new_TColorSelector { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $icon = "\xDB";    # cp437: "█"
# our $icon = encode( cp437 => "█" );

# protected attributes
has color   => ( is => 'ro', default => 0 );
has selType => ( is => 'ro', default => csBackground );

# predeclare private methods
my (
  $colorChanged,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds  => Object,
      selType => PositiveOrZeroInt, { alias => 'aSelType' },
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
  $self->{options}   |= ofSelectable | ofFirstClick | ofFramed;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aSelType)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], selType => $args[1] );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();
  $b->moveChar( 0, ' ', 0x70, $self->{size}{x} );
  for ( my $i = 0 ; $i <= $self->{size}{y} ; $i++ ) {
    if ( $i < 4 ) {
      for ( my $j = 0 ; $j < 4 ; $j++ ) {
        my $c = $i * 4 + $j;
        $b->moveChar( $j * 3, $icon, $c, 3 );
        if ( $c == $self->{color} ) {
          # We do not use the INVERSE BULLET "\x8" (U+25D8) character, but 
          # rather BULLET "\x7" (U+2022) and invert the color, since some 
          # Unicode fonts display the character differently than IBM437.
          $b->putChar( $j * 3 + 1, "\x7" );
          $b->putAttribute( $j * 3 + 1, $c == 0 ? 0x07 : ( $c << 4 ) );
        }
      }
    }
    $self->writeLine( 0, $i, $self->{size}{x}, 1, $b );
  }
  return;
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  use constant width => 4;

  $self->SUPER::handleEvent( $event );

  my $oldColor = $self->{color};
  my $maxCol = $self->{selType} == csBackground ? 7 : 15;
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      do {
        if ( $self->mouseInView( $event->{mouse}{where} ) ) {
          my $mouse = $self->makeLocal( $event->{mouse}{where} );
          $self->{color} = $mouse->{y} * 4 + int( $mouse->{x} / 3 );
        }
        else {
          $self->{color} = $oldColor;
        }
        $self->$colorChanged();
        $self->drawView();
      } while ( $self->mouseEvent( $event, evMouseMove ) );
      last;
    };
    evKeyDown == $_ and do {
      SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
        kbLeft == $_ and do {
          if ( $self->{color} > 0 ) {
            $self->{color}--;
          }
          else {
            $self->{color} = $maxCol;
          }
          last;
        };
        kbRight == $_ and do {
          if ( $self->{color} < $maxCol ) {
            $self->{color}++;
          }
          else {
            $self->{color} = 0;
          }
          last;
        };
        kbUp == $_ and do {
          if ( $self->{color} > width- 1 ) {
            $self->{color} -= width;
          }
          elsif ( $self->{color} == 0 ) {
            $self->{color} = $maxCol;
          }
          else {
            $self->{color} += $maxCol - width;
          }
          last;
        };
        kbDown == $_ and do {
          if ( $self->{color} < $maxCol - ( width- 1 ) ) {
            $self->{color} += width;
          }
          elsif ( $self->{color} == $maxCol ) {
            $self->{color} = 0;
          }
          else {
            $self->{color} -= $maxCol - width;
          }
          last;
        };
        DEFAULT: {
          return;
        }
      } #/ SWITCH: for ( ctrlToArrow( $event...))
      last;
    };
    evBroadcast == $_ and do {
      if ( $event->{message}{command} == cmColorSet ) {
        if ( $self->{selType} == csBackground ) {
          $self->{color} = $event->{message}{infoByte} >> 4;
        }
        else {
          $self->{color} = $event->{message}{infoByte} & 0x0f;
        }
        $self->drawView();
        return;
      }
      else {
        return;
      }
    };
    DEFAULT: {
      return;
    }
  }
  $self->drawView();
  $self->$colorChanged();
  $self->clearEvent( $event );
  return;
}

$colorChanged = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $msg = $self->{selType} == csForeground
          ? cmColorForegroundChanged
          : cmColorBackgroundChanged;
  message( $self->{owner}, evBroadcast, $msg, 0+ $self->{color} );
  return;
};

1

__END__

=pod

=head1 NAME

TUI::ColorSel::ColorSelector - interactive color selection view

=head1 HIERARCHY

  TObject
    TView
      TColorSelector

=head1 SYNOPSIS

  use TUI::ColorSel;

  my $selector = TColorSelector->new(
    bounds  => $bounds,
    selType => csForeground,
  );

=head1 DESCRIPTION

C<TColorSelector> implements an interactive color selection view used by the
L<TUI::Vision> color dialog infrastructure.

The selector displays a palette of available colors and allows the user to
choose a foreground or background color using keyboard or mouse input.

In foreground mode, all sixteen BIOS colors are available. In background mode,
only the eight supported background colors are selectable.

When the current selection changes, the view broadcasts either
C<cmColorForegroundChanged> or C<cmColorBackgroundChanged>, depending on the
configured selection type.

The class is typically used together with
L<TColorDisplay|TUI::ColorSel::ColorDisplay> and other color dialog components.

=head1 ATTRIBUTES

=head2 color

Currently selected color index (I<PositiveOrZeroInt>).

=head2 selType

Selection mode determining whether foreground or background colors are
edited (I<PositiveOrZeroInt>).

Typical values are C<csForeground> and C<csBackground>.

=head1 CONSTRUCTORS

=head2 new

  my $selector = TColorSelector->new(
    bounds  => $bounds,
    selType => $selType,
  );

Creates a new color selector view.

=over

=item bounds

Bounding rectangle defining the position and size of the view
(L<TRect|TUI::Objects::Rect>).

=item selType

Selection mode (I<PositiveOrZeroInt>).

Typically C<csForeground> or C<csBackground>.

=back

=head2 new_TColorSelector

  my $selector = new_TColorSelector( $bounds, $selType );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $selector->draw();

Draws the color palette and highlights the currently selected color.

=head2 handleEvent

  $selector->handleEvent($event);

Handles mouse, keyboard and broadcast events.

Keyboard navigation is performed using the cursor keys.

The selector responds to C<cmColorSet> broadcasts and updates its current
selection accordingly.

=head1 SEE ALSO

L<TColorDialog|TUI::ColorSel::ColorDialog>,
L<TView|TUI::Views::View>,
L<TColorDisplay|TUI::ColorSel::ColorDisplay>

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
