package TUI::Views::Window;
# ABSTRACT: A base class for managing windows

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TWindow
  new_TWindow
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::App::Program;
use TUI::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  :cmXXXX
  :cpXXXX
  :gfXXXX
  :ofXXXX
  :sbXXXX
  :sfXXXX
  :wfXXXX
  wpBlueWindow
);
use TUI::Views::CommandSet;
use TUI::Views::Frame;
use TUI::Views::Group;
use TUI::Views::Palette;
use TUI::Views::ScrollBar;
use TUI::Views::WindowInit;

sub TWindow() { __PACKAGE__ }
sub name() { 'TWindow' }
sub new_TWindow { __PACKAGE__->from(@_) }

extends ( TGroup, TWindowInit );

# declare global variables
our $minWinSize = TPoint->new( x => 16, y => 6 );

# import global variables
use vars qw(
  $appPalette
);
{
  no strict 'refs';
  *appPalette = \${ TProgram . '::appPalette' };
}

# public attributes
has flags    => ( is => 'rw', default => wfMove | wfGrow | wfClose | wfZoom );
has zoomRect => ( is => 'rw' );
has number   => ( is => 'rw', default => sub { 'required' } );
has palette  => ( is => 'rw', default => wpBlueWindow );
has frame    => ( is => 'rw' );
has title    => ( is => 'rw', default => sub { 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      title  => Str, { alias => 'aTitle' },
      number => Int, { alias => 'aNumber' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = TGroup->BUILDARGS( bounds => $args1->{bounds} );
  my $args3 = TWindowInit->BUILDARGS( cFrame => $class->can( 'initFrame' ) );
  return { %$args1, %$args2, %$args3 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{zoomRect} = $self->getBounds();

  $self->{state}   |= sfShadow;
  $self->{options} |= ofSelectable | ofTopSelect;
  $self->{growMode} = gfGrowAll | gfGrowRel;

  if ( $self->{createFrame}
    && ( $self->{frame} = $self->createFrame( $self->getExtent() ) )
  ) {
    $self->insert( $self->{frame} );
  }
  return;
}

sub from {    # $obj ($bounds, $aTitle, $aNumber)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], title => $args[1], 
    number => $args[2] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{title} = undef;
  return;
}

sub close {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  alias: for $self ( $_[0] ) {    # Maybe we are destroying ourselves
  if ( $self->valid( cmClose ) ) {
    # so we don't try to use the frame after it's been deleted
    $self->{frame} = undef;
    $self->destroy( $self );
  }
  return;
  } #/ alias
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $blue = TPalette->new(
    data => cpBlueWindow,
    size => length( cpBlueWindow ) 
  );
  state $cyan = TPalette->new( 
    data => cpCyanWindow,
    size => length( cpCyanWindow ) 
  );
  state $gray = TPalette->new( 
    data => cpGrayWindow,
    size => length( cpGrayWindow ) 
  );
  state $palettes = [ $blue, $cyan, $gray ];
  return $palettes->[$appPalette]->clone();
} #/ sub getPalette

sub getTitle {    # $str ($maxSize)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $maxSize ) = $sig->( @_ );
  return $self->{title};
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  my $limits = TRect->new();
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      cmResize == $_ and do {
        if ( $self->{flags} & ( wfMove | wfGrow ) ) {
          $limits = $self->{owner}->getExtent();
          $self->sizeLimits( $min, $max );
          $self->dragView( $event, 
            $self->{dragMode} | ( $self->{flags} & ( wfMove | wfGrow ) ), 
            $limits, $min, $max
          );
          $self->clearEvent( $event );
        }
        last;
      };
      cmClose == $_ and do {
        no warnings 'uninitialized';
        if ( ( $self->{flags} & wfClose )
          && ( !$event->{message}{infoPtr}
            ||  $event->{message}{infoPtr} == $self
          ) 
        ) {
          $self->clearEvent( $event );
          if ( !( $self->{state} & sfModal ) ) {
            $self->close();
          }
          else {
            $event->{what} = evCommand;
            $event->{message}{command} = cmCancel;
            $self->putEvent( $event );
            $self->clearEvent( $event );
          }
        } #/ if ( $self->{flags} & ...)
        last;
      };
      cmZoom == $_ and do {
        no warnings 'uninitialized';
        if ( ( $self->{flags} & wfZoom )
          && ( !$event->{message}{infoPtr} 
            ||  $event->{message}{infoPtr} == $self
          )
        ) {
          $self->zoom();
          $self->clearEvent( $event );
        }
        last;
      };
    }
  }
  elsif ( $event->{what} == evKeyDown ) {
    SWITCH: for ( $event->{keyDown}{keyCode} ) {
      kbTab == $_ and do {
        $self->focusNext( false );
        $self->clearEvent( $event );
        last;
      };
      kbShiftTab == $_ and do {
        $self->focusNext( true );
        $self->clearEvent( $event );
        last;
      };
    }
  } #/ elsif ( $event->{what} ==...)
  elsif ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmSelectWindowNum
    && $event->{message}{infoInt} == $self->{number}
    && ( $self->{options} & ofSelectable )
  ) {
    $self->select();
    $self->clearEvent( $event );
  }
  return;
} #/ sub handleEvent

sub initFrame {    # $frame ($r)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $r ) = $sig->( @_ );
  return TFrame->new( bounds => $r );
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  my $windowCommands = TCommandSet->new();

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & sfSelected ) {
    $self->setState( sfActive, $enable );
    if ( $self->{frame} ) {
      $self->{frame}->setState( sfActive, $enable );
    }
    $windowCommands += cmNext;
    $windowCommands += cmPrev;
    if ( $self->{flags} & ( wfGrow | wfMove ) ) {
      $windowCommands += cmResize;
    }
    if ( $self->{flags} & wfClose ) {
      $windowCommands += cmClose;
    }
    if ( $self->{flags} & wfZoom ) {
      $windowCommands += cmZoom;
    }
    if ( $enable ) {
      $self->enableCommands( $windowCommands );
    }
    else {
      $self->disableCommands( $windowCommands );
    }
  } #/ if ( $aState & sfSelected)
  return;
} #/ sub setState

sub sizeLimits {    # void ($min, $max)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object],
  );
  my ( $self, $min, $max ) = $sig->( @_ );
  alias: for $min ( $_[1] ) {
  alias: for $max ( $_[2] ) {
  $self->SUPER::sizeLimits( $min, $max );
  $min = $minWinSize->clone();
  return;
  }} #/ alias:
}

sub standardScrollBar {    # $scrollBar ($aOptions)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $aOptions ) = $sig->( @_ );
  my $r = $self->getExtent();
  if ( $aOptions & sbVertical ) {
    $r = TRect->new(
      ax => $r->{b}{x} - 1, ay => $r->{a}{y} + 1,
      bx => $r->{b}{x},     by => $r->{b}{y} - 1,
    );
  }
  else {
    $r = TRect->new(
      ax => $r->{a}{x} + 2, ay => $r->{b}{y} - 1, 
      bx => $r->{b}{x} - 2, by => $r->{b}{y},
    );
  }

  my $s = TScrollBar->new( bounds => $r );
  $self->insert( $s );
  if ( $aOptions & sbHandleKeyboard ) {
    $s->{options} |= ofPostProcess;
  }
  return $s;
} #/ sub standardScrollBar

sub zoom {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my ( $minSize, $maxSize ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minSize, $maxSize );
  if ( $self->{size} != $maxSize ) {
    $self->{zoomRect} = $self->getBounds();
    my $r = TRect->new( 
      ax => 0, ay => 0, bx => $maxSize->{x}, by => $maxSize->{y}
    );
    $self->locate( $r );
  }
  else {
    $self->locate( $self->{zoomRect} );
  }
  return;
} #/ sub zoom

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{frame} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Views::Window - base class for windows in TUI::Vision

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow

=head1 SYNOPSIS

  use TUI::Views;

  my $window = TWindow->new(
    bounds => $bounds,
    title  => 'Title',
    number => 1
  );

=head1 DESCRIPTION

C<TWindow> is a core view class used to represent windows in a TUI::Vision
application. Windows may contain other views, display optional titles and
window numbers, and support standard window operations such as moving,
resizing, closing, and zooming.

The class encapsulates the behavior required for managing window frames,
handling window-specific commands, and maintaining optional scroll bars.
Dialog boxes and many other high-level interface elements are implemented as
specialized window descendants.

Most applications interact with C<TWindow> indirectly through subclasses or
by responding to window-related events.

=head1 VARIABLES

The following global variable defines default size constraints
for C<TWindow>.

=head2 $minWinSize

Specifies the minimum allowed window size, represented as a C<TPoint>.

=head1 ATTRIBUTES

The following attributes define the state and appearance of a window. Unless
otherwise noted, attributes are part of the public window state.

=over

=item flags

Window behavior flags (I<Int>), typically a combination of C<wfXXXX>
constants. These flags control whether the window can be moved, resized,
closed, or zoomed.

=item frame

Reference to the window frame object (I<TFrame>).  
This attribute is created internally and represents the visual border of the
window.

=item number

Window number identifier (I<Int>).  
If the value is between 1 and 9, the window can be selected directly using the
C<Alt-n> key combination.

=item palette

Palette selector for the window (I<Int>).  
Determines which predefined window palette is used.

=item title

Title string displayed in the window frame (I<Str>).

=item zoomRect

Rectangle storing the window's normal (unzoomed) bounds (I<TRect>).  
This value is used to restore the window when toggling the zoom state.

=back

=head1 CONSTRUCTOR

=head2 new

  my $obj = TWindow->new(
    bounds => $bounds,
    title  => $title,
    number => $number
  );

Creates a new window with the specified bounds, title, and window number.

=over

=item bounds

Bounding rectangle of the window (I<TRect>).

=item title

Title string displayed in the window frame (I<Str>).

=item number

Window number identifier (I<Int>).  
Values from 1 to 9 allow direct keyboard selection.

=back

=head2 new_TWindow

  my $obj = new_TWindow($bounds, $aTitle, $aNumber);

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns and is functionally equivalent to calling C<new> with
named parameters.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the window and removes it from the view hierarchy.

This method corresponds to the Turbo Vision destructor and is normally invoked
automatically by the owning group or application.

=head1 METHODS

=head2 close

  $self->close();

Closes the window. This is functionally equivalent to invoking the window
destructor and is typically triggered by the C<cmClose> command.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the color palette associated with the window.

=head2 getTitle

  my $str = $self->getTitle($maxSize);

Returns the window title. Subclasses may override this method to truncate or
modify the title if it exceeds the specified maximum length.

=head2 handleEvent

  $self->handleEvent($event);

Handles events directed at the window. Applications commonly override this
method to intercept window-related commands such as close or zoom.

=head2 initFrame

  my $frame = $self->initFrame($bounds);

Creates and initializes the window frame. Subclasses may override this method
to provide a custom frame implementation.

=head2 setState

  $self->setState($state, $enable);

Sets or clears state flags and performs additional window-specific processing
when the window becomes active or inactive.

=head2 shutDown

  $self->shutDown();

Shuts down the window and releases associated resources.

=head2 sizeLimits

  $self->sizeLimits($min, $max);

Determines the minimum and maximum size limits for the window.

=head2 standardScrollBar

  my $scrollBar = $self->standardScrollBar($options);

Creates and inserts a standard scroll bar into the window. The C<$options>
parameter specifies orientation and keyboard handling using C<sbXXXX>
constants.

=head2 zoom

  $self->zoom();

Toggles the window between its zoomed state and its normal size stored in
L</zoomRect>.

=head1 SEE ALSO

L<TUI::Views::View>, L<TUI::Views::Group>, L<TUI::Views::Frame>

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
