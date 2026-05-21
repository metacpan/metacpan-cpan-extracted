package TUI::Menus::StatusLine;
# ABSTRACT: Message line for the bottom of the application screen

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusLine
  new_TStatusLine
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Menus::Const qw( cpStatusLine );
use TUI::Drivers::Const qw( :evXXXX );
use TUI::Drivers::Util qw( cstrlen );
use TUI::Views::DrawBuffer;
use TUI::Views::Const qw(
  cmCommandSetChanged
  :gfXXXX
  hcNoContext
  ofPreProcess
);
use TUI::Views::Palette;
use TUI::Views::View;

sub TStatusLine() { __PACKAGE__ }
sub name() { 'TStatusLine' }
sub new_TStatusLine { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $hintSeparator = "\xB3 ";

# protected attributes
has items => ( is => 'ro' );
has defs  => ( is => 'ro', default => sub { die 'required' } );

# predeclare private methods
my (
  $drawSelect,
  $findItems,
  $itemMouseIsIn,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      defs   => Maybe[Object], { alias => 'aDefs' },
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
  $self->{options}   |= ofPreProcess;
  $self->{eventMask} |= evBroadcast;
  $self->{growMode}   = gfGrowLoY | gfGrowHiX | gfGrowHiY;
  $self->$findItems();
  return;
} #/ sub new

sub from {    # $obj ($bounds, $aDefs|undef)
  state $sig = signature(
    method => 1,
    pos    => [ Object, Maybe[Object] ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], defs => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  while ( $self->{defs} ) {
    my $T = $self->{defs};
    $self->{defs} = $self->{defs}{next};
    $self->disposeItems( $T->{items} );
    undef $T;
  }
  return;
}

sub disposeItems {    # void ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $item ) = $sig->( @_ );
  while ( $item ) {
    alias: for my $T ( $item ) {
    $item = $item->next;
    undef $T;
    } #/ alias
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->$drawSelect( undef );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpStatusLine, 
    size => length( cpStatusLine ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  SWITCH: for ( $event->{what} ) {
    $_ == evMouseDown and do {
      my $T;
      do {
        my $mouse = $self->makeLocal( $event->{mouse}{where} );
        if ( $T != $self->$itemMouseIsIn( $mouse ) ) {
          $self->$drawSelect( $T = $self->$itemMouseIsIn( $mouse ) );
        }
      } while ( $self->mouseEvent( $event, evMouseMove ) );

      if ( $T && TView->commandEnabled( $T->{command} ) ) {
        $event->{what} = evCommand;
        $event->{message}{command} = $T->{command};
        $event->{message}{infoPtr} = undef;
        $self->putEvent( $event );
      }
      $self->clearEvent( $event );
      $self->drawView();
      last;
    };
    $_ == evKeyDown and do {
      my $T = $self->{items};
      while ( $T ) {
        if ( $event->{keyDown}{keyCode} == $T->{keyCode}
          && TView->commandEnabled( $T->{command} ) )
        {
          $event->{what} = evCommand;
          $event->{message}{command} = $T->{command};
          $event->{message}{infoPtr} = undef;
          return;
        }
        $T = $T->{next};
      } #/ while ( $T )
      last;
    };
    $_ == evBroadcast and do {
      if ( $event->{message}{command} == cmCommandSetChanged
      ) {
        $self->drawView();
      }
      last;
    };
  }
  return;
} #/ sub handleEvent

sub hint {    # $str ($aHelpCtx)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $aHelpCtx ) = $sig->( @_ );
  return '';
}

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $p = $self->TopView();
  my $h = $p ? $p->getHelpCtx() : hcNoContext;
  if ( $self->{helpCtx} != $h ) {
    $self->{helpCtx} = $h;
    $self->$findItems();
    $self->drawView();
  }
  return;
} #/ sub update

$drawSelect = sub {    # void ($selected|undef)
  my ( $self, $selected ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( !defined $selected or is_Object $selected );
  my $b = TDrawBuffer->new();

  my $cNormal       = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  $b->moveChar( 0, ' ', $cNormal, $self->{size}{x} );
  my $T = $self->{items};
  my $i = 0;

  while ( $T ) {
    if ( $T->{text} ) {
      my $l = cstrlen( $T->{text} );
      if ( $i + $l < $self->{size}{x} ) {
        no warnings 'uninitialized';
        my $color;
        if ( TView->commandEnabled( $T->{command} ) ) {
          $color = ( $T == $selected )
                 ? $cSelect 
                 : $cNormal;
        }
        else {
          $color = ( $T == $selected )
                 ? $cSelDisabled 
                 : $cNormDisabled;
        }
        $b->moveChar( $i, ' ', $color, 1 );
        $b->moveCStr( $i + 1, $T->{text}, $color );
        $b->moveChar( $i + $l + 1, ' ', $color, 1 );
      } #/ if ( $i + $l < $self->...)
      $i += $l + 2;
    } #/ if ( $T->{text} )
    $T = $T->{next};
  } #/ while ( $T )
  if ( $i < $self->{size}{x} - 2 ) {
    my $hintBuf = $self->hint( $self->{helpCtx} );
    if ( $hintBuf ne '' ) {
      $b->moveStr( $i, $hintSeparator, $cNormal );
      $i += 2;
      if ( length( $hintBuf ) + $i > $self->{size}{x} ) {
        $hintBuf = substr( $hintBuf, 0, $self->{size}{x} - $i );
      }
      $b->moveStr( $i, $hintBuf, $cNormal );
      $i += length( $hintBuf );
    }
  } #/ if ( $i < $self->{size...})
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  return;
}; #/ sub drawSelect

$findItems = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $p = $self->{defs};
  while ( $p 
    && ( $self->{helpCtx} < $p->{min} || $self->{helpCtx} > $p->{max} ) 
  ) {
    $p = $p->{next};
  }
  $self->{items} = $p ? $p->{items} : undef;
  return;
};

$itemMouseIsIn = sub {    # $statusItem|undef ($mouse)
  my ( $self, $mouse ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashLike $mouse );
  return undef
    if $mouse->{y} != 0;

  my $i = 0;
  my $T = $self->{items};

  while ( $T ) {
    if ( $T->{text} ) {
      my $k = $i + cstrlen( $T->{text} ) + 2;
      return $T 
        if $mouse->{x} >= $i && $mouse->{x} < $k;
      $i = $k;
    }
    $T = $T->{next};
  }
  return undef;
}; #/ sub itemMouseIsIn

1

__END__

=pod

=head1 NAME

TUI::Menus::StatusLine - defines the class TStatusLine

=head1 HIERARCHY

  TObject
    TView
      TStatusLine

=head1 DESCRIPTION

C<TStatusLine> represents the message line displayed at the bottom of a Turbo
Vision application. It shows context-sensitive key hints and status messages
associated with menu items and commands.

A status line is typically created during application initialization and is
updated automatically as the active help context changes. Internally, the
status line selects an appropriate status definition and renders the
corresponding status items.

In addition to displaying key bindings, C<TStatusLine> can provide short,
context-sensitive hints that vary depending on the currently active menu or
view. This behavior is commonly customized by overriding the C<hint> method in
a subclass.

=head1 VARIABLES

The following global variable affects the visual rendering of C<TStatusLine>.

=head2 $hintSeparator

Defines the character sequence used to separate individual hints
in the status line. The default value uses a CP437 vertical separator.

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors and are intended
for internal use by the status line implementation.

=over

=item defs

Read-only reference to the linked list of status definitions
(I<TStatusDef>). This attribute is required and defines which status items
apply to which help context ranges.

=item items

Read-only reference to the currently active list of status items
(I<TStatusItem>). This list is managed internally and updated as the help
context changes.

=back

=head1 METHODS

=head2 new

  my $obj = TStatusLine->new(
    bounds => $bounds,
    defs   => $defs
  );

Creates a new status line object at the position specified by C<$bounds> and
initializes it with a list of status definitions.

=over

=item bounds

Bounding rectangle of the status line (I<TRect>).  
The height is typically one row and the line is placed at the bottom of the
desktop.

=item defs

Status definition list associated with this status line
(I<TStatusDef>). This parameter is required.

=back

=head2 new_TStatusLine

  my $obj = new_TStatusLine($bounds, $aDefs | undef);

Factory constructor for creating a status line instance.

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Performs cleanup of the status line object and disposes of associated resources.
This method is normally called automatically by the owning view or application.

=head2 disposeItems

  $self->disposeItems($item | undef);

Releases the current list of status items. This method is used internally during
updates and cleanup.

=head2 draw

  $self->draw();

Draws the status line using the currently active status items and any
context-sensitive hint text.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the color palette used to draw the status line. Subclasses may override
this method to provide alternative color mappings.

=head2 handleEvent

  $self->handleEvent($event);

Processes mouse and keyboard events occurring on the status line. When a status
item is selected, the corresponding command is generated and dispatched.

=head2 hint

  my $str = $self->hint($aHelpCtx);

Translates a help context identifier into a short hint string that is displayed
on the status line.

This method is intended to be overridden in subclasses to provide
application-specific, context-sensitive help text. The default implementation
returns an empty string.

=head2 update

  $self->update();

Updates the status line contents based on the current help context. This method
selects the appropriate status definition and rebuilds the list of visible
status items.

=head1 EXAMPLE

The following example shows a typical status line definition using chained
status items and a single status definition that applies to all help contexts.

  sub initStatusLine {
    my ( $class, $bounds ) = @_;

    $bounds->{a}{y} = $bounds->{b}{y} - 1;

    return new_TStatusLine(
      $bounds,
      new_TStatusDef( 0, 0xFFFF )
        + new_TStatusItem( '~Alt+X~ Exit', kbAltX, cmQuit )
        + new_TStatusItem( '~F10~ Menu', kbF10, cmMenu )
        + new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
    );
  }

This pattern mirrors the traditional Turbo Vision status line construction
while using Perl-specific operator overloading for clarity.

=head1 SEE ALSO

L<TUI::Menus::StatusDef>, L<TUI::Menus::StatusItem>

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
