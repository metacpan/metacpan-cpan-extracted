package TUI::Views::Scroller;
# ABSTRACT: Base class for scrolling text windows

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScroller
  new_TScroller
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Const qw( 
  evBroadcast
);
use TUI::Objects::Point;
use TUI::Views::Const qw(
  cmScrollBarChanged
  cpScroller
  ofSelectable
  sfActive
  sfDragging
  sfSelected
);
use TUI::Views::Palette;
use TUI::Views::View;

sub TScroller() { __PACKAGE__ }
sub name() { 'TScroller' }
sub new_TScroller { __PACKAGE__->from(@_) }

extends TView;

# public attributes
has delta      => ( is => 'rw', default => sub { TPoint->new } );

# protected attributes
has drawLock   => ( is => 'ro', default => 0 );
has drawFlag   => ( is => 'ro', default => false );
has hScrollBar => ( is => 'ro', default => sub { die 'required' } );
has vScrollBar => ( is => 'ro', default => sub { die 'required' } );
has limit      => ( is => 'ro', default => sub { TPoint->new } );

# predeclare private methods
my (
  $showSBar,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
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
  $self->{delta}{x} = $self->{delta}{y} = 0;
  $self->{limit}{x} = $self->{limit}{y} = 0;
  $self->{options}   |= ofSelectable;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aHScrollBar|undef, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2] );
}

sub changeBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->setBounds( $bounds );
  $self->{drawLock}++;
  $self->setLimit( $self->{limit}{x}, $self->{limit}{y} );
  $self->{drawLock}--;
  $self->{drawFlag} = false;
  $self->drawView();
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpScroller, 
    size => length( cpScroller ),
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
  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmScrollBarChanged
    && ( $event->{message}{infoPtr} == $self->{hScrollBar}
      || $event->{message}{infoPtr} == $self->{vScrollBar} )
  ) {
    $self->scrollDraw();
  }
  return;
} #/ sub handleEvent

sub scrollDraw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $d = TPoint->new();

  if ( $self->{hScrollBar} ) {
    $d->{x} = $self->{hScrollBar}{value};
  }
  else {
    $d->{x} = 0;
  }
  if ( $self->{vScrollBar} ) {
    $d->{y} = $self->{vScrollBar}{value};
  }
  else {
    $d->{y} = 0;
  }
  if ( $d->{x} != $self->{delta}{x} || $d->{y} != $self->{delta}{y} ) {
    $self->setCursor(
      $self->{cursor}{x} + $self->{delta}{x} - $d->{x},
      $self->{cursor}{y} + $self->{delta}{y} - $d->{y}
    );
    $self->{delta} = $d;
    if ( $self->{drawLock} ) {
      $self->{drawFlag} = true;
    }
    else {
      $self->drawView();
    }
  } #/ if ( $d->{x} != $self->...)
  return;
}

sub scrollTo {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  $self->{drawLock}++;
  $self->{hScrollBar}->setValue( $x )
    if $self->{hScrollBar};
  $self->{vScrollBar}->setValue( $y )
    if $self->{vScrollBar};
  $self->{drawLock}--;
  $self->checkDraw();
  return;
}

sub setLimit {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  $self->{limit}{x} = $x;
  $self->{limit}{y} = $y;
  $self->{drawLock}++;
  $self->{hScrollBar}->setParams(
    $self->{hScrollBar}{value},
    0,
    $x - $self->{size}{x},
    $self->{size}{x} - 1,
    $self->{hScrollBar}{arStep}
  ) if $self->{hScrollBar};
  $self->{vScrollBar}->setParams(
    $self->{vScrollBar}{value},
    0,
    $y - $self->{size}{y},
    $self->{size}{y} - 1,
    $self->{vScrollBar}{arStep}
  ) if $self->{vScrollBar};
  $self->{drawLock}--;
  $self->checkDraw();
  return;
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  $self->drawView()
    if $aState & ( sfActive | sfDragging );
  return;
} #/ sub setState

sub checkDraw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{drawLock} == 0 && $self->{drawFlag} ) {
    $self->{drawFlag} = false;
    $self->drawView();
  }
  return;
} #/ sub checkDraw

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{hScrollBar} = undef;
  $self->{vScrollBar} = undef;
  $self->SUPER::shutDown();
  return;
}

$showSBar = sub {    # void ($sBar|undef)
  my ( $self, $sBar ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( !defined $sBar or is_Object $sBar );
  if ( $sBar ) {
    ( $self->getState( sfActive | sfSelected ) )
      ? $sBar->show()
      : $sBar->hide();
  }
  return;
};

1

__END__

=pod

=head1 NAME

TUI::Views::Scroller - base class for scrollable views in TUI::Vision

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TTextDevice
          TTerminal

=head1 SYNOPSIS

  use TUI::Views;

  my $scroller = TScroller->new(
    bounds      => $bounds,
    aHScrollBar => $hBar,
    aVScrollBar => $vBar
  );
  
  $scroller->setLimit(100, 50);
  $scroller->scrollTo(10, 5);

=head1 DESCRIPTION

C<TScroller> provides the core infrastructure for scrollable views in Turbo
Vision. It maintains a two-dimensional scroll offset and coordinates scrolling
behavior between the view and optional horizontal and vertical scroll bars.

The class itself does not render content. Instead, it serves as a base class
for views that display scrollable data, such as text devices and terminal-like
output views. Descendants are responsible for drawing their content relative to
the current scroll position.

C<TScroller> keeps its internal scroll offset synchronized with attached scroll
bars. When the scroll bars change, the scroller updates its offset and redraws
the view. Conversely, programmatic changes to the scroll position are reflected
in the scroll bars.

=head1 ATTRIBUTES

The following attributes describe the scrolling state of the view. Attributes
marked as read-only are managed internally.

=over

=item delta

Current scroll offset as a point (I<TPoint>).  
Represents the horizontal and vertical scroll position.

=item limit

Maximum allowed scroll offset (I<TPoint>).  
Defines the bounds of the scrollable area.

=item aHScrollBar

Reference to the horizontal scroll bar (I<TScrollBar>), if present.

=item aVScrollBar

Reference to the vertical scroll bar (I<TScrollBar>), if present.

=item drawLock

Internal counter used to suppress redraw operations during batch updates.

=item drawFlag

Indicates whether a redraw is pending once drawing is re-enabled.

=back

=head1 CONSTRUCTOR

=head2 new

  my $scroller = TScroller->new(
    bounds      => $bounds,
    aHScrollBar => $hBar,
    aVScrollBar => $vBar
  );

Creates a new scroller with the specified bounds and optional scroll bars.

=over

=item bounds

Bounding rectangle of the scroller (I<TRect>).

=item aHScrollBar

Horizontal scroll bar associated with the scroller (I<TScrollBar> or undef).

=item aVScrollBar

Vertical scroll bar associated with the scroller (I<TScrollBar> or undef).

=back

=head2 new_TScroller

  my $scroller = new_TScroller($bounds, $hBar | undef, $vBar | undef);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the scroller and releases references to associated scroll bars. This
method corresponds to the Turbo Vision destructor and is normally invoked
automatically.

=head1 METHODS

=head2 changeBounds

  $scroller->changeBounds($bounds);

Updates the bounds of the scroller and recalculates internal geometry.

=head2 checkDraw

  $scroller->checkDraw();

Performs a deferred redraw if drawing was previously suppressed.

=head2 getPalette

  my $palette = $scroller->getPalette();

Returns the color palette used by the scroller.

=head2 handleEvent

  $scroller->handleEvent($event);

Processes events relevant to scrolling, including notifications from attached
scroll bars.

=head2 scrollDraw

  $scroller->scrollDraw();

Synchronizes the internal scroll offset with the scroll bar values and redraws
the view if necessary.

=head2 scrollTo

  $scroller->scrollTo($x, $y);

Sets the scroll position to the specified coordinates.

=head2 setLimit

  $scroller->setLimit($x, $y);

Defines the maximum scrollable range and updates the scroll bars accordingly.

=head2 setState

  $scroller->setState($state, $enable);

Updates the state flags of the scroller and redraws if required.

=head2 shutDown

  $scroller->shutDown();

Shuts down the scroller and clears associated resources.

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
