package TUI::Dialogs::Button;
# ABSTRACT: Pushbutton control for dialogs

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TButton
  new_TButton
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Dialogs::Const qw(
  :bfXXXX
  :cmXXXX
  cpButton
);
use TUI::Dialogs::Util qw( hotKey );
use TUI::Drivers::Const qw( :evXXXX );
use TUI::Drivers::Event;
use TUI::Drivers::Util qw(
  cstrlen
  getAltCode
);
use TUI::Views::Const qw(
  cmDefault
  cmCommandSetChanged
  :ofXXXX
  phPostProcess
  :sfXXXX
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;
use TUI::Views::Util qw( message );

sub TButton() { __PACKAGE__ }
sub name() { 'TButton' }
sub new_TButton { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $shadows = "\xDC\xDB\xDF";
our $markers = "[]";

# import global variables
use vars qw(
  $showMarkers
  $specialChars
);
{
  no strict 'refs';
  *showMarkers  = \${ TView . '::showMarkers' };
  *specialChars = \${ TView . '::specialChars' };
}

# public attributes
has title     => ( is => 'ro', default => sub { die 'required' } );

# protected attributes
has command   => ( is => 'ro', default => sub { die 'required' } );
has flags     => ( is => 'ro', default => sub { die 'required' } );
has amDefault => ( is => 'ro', default => false );

# predeclare private methods
my (
  $drawTitle,
  $pressButton,
  $getActiveRect,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds  => Object,
      title   => Str,               { alias => 'aTitle' },
      command => PositiveOrZeroInt, { alias => 'aCommand' },
      flags   => PositiveOrZeroInt, { alias => 'aFlags' },
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
  $self->{amDefault} = ( $self->{flags} & bfDefault ) != 0;
  $self->{options} |=
    ofSelectable | ofFirstClick | ofPreProcess | ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  $self->{state}     |= sfDisabled
    unless TView->commandEnabled( $self->{command} );
  return;
}

sub from {    # $obj ($bounds, $aTitle, $aCommand, $aFlags)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str, PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], title => $args[1], 
    command => $args[2], flags => $args[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{title} = undef;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawState( false );
  return;
}

sub drawState {    # void ($down)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $down ) = $sig->( @_ );

  my ( $cButton, $cShadow );
  my $ch;
  my $i;
  my $b = TDrawBuffer->new();

  if ( $self->{state} & sfDisabled ) {
    $cButton = $self->getColor( 0x0404 );
  }
  else {
    $cButton = $self->getColor( 0x0501 );
    if ( $self->{state} & sfActive ) {
      if ( $self->{state} & sfSelected ) {
        $cButton = $self->getColor( 0x0703 );
      }
      elsif ( $self->{amDefault} ) {
        $cButton = $self->getColor( 0x0602 );
      }
    }
  } #/ else [ if ( $self->{state} ...)]

  $cShadow = $self->getColor( 8 );

  my $s = $self->{size}{x} - 1;
  my $T = int( $self->{size}{y} / 2 ) - 1;

  for ( my $y = 0 ; $y <= $self->{size}{y} - 2 ; $y++ ) {
    $b->moveChar( 0, ' ', $cButton, $self->{size}{x} );
    $b->putAttribute( 0, $cShadow );
    if ( $down ) {
      $b->putAttribute( 1, $cShadow );
      $ch = ' ';
      $i  = 2;
    }
    else {
      $b->putAttribute( $s, $cShadow );
      if ( $showMarkers ) {
        $ch = ' ';
      }
      else {
        if ( $y == 0 ) {
          $b->putChar( $s, substr( $shadows, 0, 1 ) );
        }
        else {
          $b->putChar( $s, substr( $shadows, 1, 1 ) );
        }
        $ch = substr( $shadows, 2, 1 );
      }
      $i = 1;
    } #/ else [ if ( $down ) ]

    if ( $y == $T && $self->{title} ) {
      $self->$drawTitle( $b, $s, $i, $cButton, $down );
    }

    if ( $showMarkers && !$down ) {
      $b->putChar( 1,      substr( $markers, 0, 1 ) );
      $b->putChar( $s - 1, substr( $markers, 1, 1 ) );
    }

    $self->writeLine( 0, $y, $self->{size}{x}, 1, $b );
  } #/ for ( my $y = 0 ; $y <=...)

  $b->moveChar( 0, ' ', $cShadow, 2 );
  $b->moveChar( 2, $ch, $cShadow, $s - 1 );

  $self->writeLine( 0, $self->{size}{y} - 1, $self->{size}{x}, 1, $b );
  return;
} #/ sub drawState

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpButton, 
    size => length( cpButton ),
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

  my $mouse; 
  my $clickRect;

  $clickRect = $self->getExtent();
  $clickRect->{a}{x}++;
  $clickRect->{b}{x}--;
  $clickRect->{b}{y}--;

  if ( $event->{what} == evMouseDown ) {
    $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( !$clickRect->contains( $mouse ) ) {
      $self->clearEvent( $event );
    }
  }
  if ( $self->{flags} & bfGrabFocus ) {
    $self->SUPER::handleEvent( $event );
  }

  my $c = hotKey( $self->{title} );
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
     if ( ( $self->{state} & sfDisabled ) == 0 ) {
        $clickRect->{b}{x}++;
        my $down = false;
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          if ( !$down != !$clickRect->contains( $mouse ) ) {
            $down = !$down;
            $self->drawState( $down );
          }
        } while ( $self->mouseEvent( $event, evMouseMove ) );
        if ( $down ) {
          $self->press();
          $self->drawState( false );
        }
      } #/ if ( ( $self->{state} ...))
      $self->clearEvent( $event );
      last;
    };

    evKeyDown == $_ and do {
      if (
        $event->{keyDown}{keyCode} == getAltCode( $c )
        || ( $self->{owner}{phase} == phPostProcess
          && $c
          && uc( $event->{keyDown}{charScan}{charCode} ) eq $c )
        || ( ( $self->{state} & sfFocused )
          && $event->{keyDown}{charScan}{charCode} eq ' ' )
        )
      {
        $self->press();
        $self->clearEvent( $event );
      } #/ if ( $event->{keyDown}...)
      last;
    };

    evBroadcast == $_ and do {
      local $_;
      SWITCH: for ( $event->{message}{command} ) {
        cmDefault == $_ and do {
          if ( $self->{amDefault} && !( $self->{state} & sfDisabled ) ) {
            $self->press();
            $self->clearEvent( $event );
          }
          last;
        };

        cmGrabDefault == $_ || 
        cmReleaseDefault == $_ and do {
          if ( $self->{flags} & bfDefault ) {
            $self->{amDefault} = $event->{message}{command} == cmReleaseDefault;
            $self->drawView();
          }
          last;
        };

        cmCommandSetChanged == $_ and do {
          $self->setState(
            sfDisabled,
            !TView->commandEnabled( $self->{command} ) ? true : false
          );
          $self->drawView();
          last;
        };
      } #/ SWITCH: for ( $event->{message}...)
      last;
    };

  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub makeDefault {    # void ($enable)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $enable ) = $sig->( @_ );

  if ( ( $self->{flags} & bfDefault ) == 0 ) {
    message(
      $self->{owner},
      evBroadcast,
      $enable ? cmGrabDefault : cmReleaseDefault,
      $self
    );
    $self->{amDefault} = $enable;
    $self->drawView();
  } #/ if ( ( $self->{flags} ...))
  return;
} #/ sub makeDefault

sub press {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  message( $self->{owner}, evBroadcast, cmRecordHistory, undef );

  if ( $self->{flags} & bfBroadcast ) {
    message( $self->{owner}, evBroadcast, $self->{command}, $self );
  }
  else {
    my $e = TEvent->new();
    $e->{what} = evCommand;
    $e->{message}{command} = $self->{command};
    $e->{message}{infoPtr} = $self;
    $self->putEvent( $e );
  }
  return;
} #/ sub press

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & ( sfSelected | sfActive ) ) {
    if ( !$enable ) {
      # BUG FIX - EFW - Thu 10/19/95
      $self->{state} &= ~sfFocused;
      $self->makeDefault( false );
    }
    $self->drawView();
  }

  if ( $aState & sfFocused ) {
    $self->makeDefault( $enable );
  }
  return;
} #/ sub setState

$drawTitle = sub {    # void ($b, $s, $i, $cButton, $down)
  my ( $self, $b, $s, $i, $cButton, $down ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $b );
  assert ( is_Int $s );
  assert ( is_Int $i );
  assert ( is_PositiveOrZeroInt $cButton );
  assert ( is_Bool $down );

  my ( $l, $scOff );
  if ( $self->{flags} & bfLeftJust ) {
    $l = 1;
  }
  else {
    my $len = cstrlen( $self->{title} );
    $l = int( ( $s - $len - 1 ) / 2 );
    $l = 1 if $l < 1;
  }

  $b->moveCStr( $i + $l, $self->{title}, $cButton );

  if ( $showMarkers && !$down ) {
    if ( $self->{state} & sfSelected ) {
      $scOff = 0;
    }
    elsif ( $self->{amDefault} ) {
      $scOff = 2;
    }
    else {
      $scOff = 4;
    }
    $b->putChar( 0,  $specialChars->[$scOff] );
    $b->putChar( $s, $specialChars->[$scOff + 1] );
  } #/ if ( $self->{showMarkers...})
  return;
}; #/ sub drawTitle

$pressButton = sub {    # void ($event)
  assert ( @_ == 2 );
  assert ( is_Object $_[0] );
  assert ( is_Object $_[1] );
  ...;
};

$getActiveRect = sub {    # $rect ()
  assert ( @_ == 1 );
  assert ( is_Object $_[0] );
  ...;
};

1

__END__

=pod

=head1 NAME

TUI::Dialogs::Button - pushbutton control for dialogs

=head1 HIERARCHY

  TObject
    TView
      TButton

=head1 SYNOPSIS

  use TUI::Dialogs;
  use TUI::Objects;

  my $dialog = TDialog->new(
    bounds => TRect->new(ax => 10, ay => 4, bx => 44, by => 15),
    title  => 'Confirm'
  );

  my $ok = TButton->new(
    bounds  => TRect->new(ax => 7, ay => 8, bx => 17, by => 10),
    title   => '~O~K',
    command => cmOK,
    flags   => bfDefault
  );

  my $cancel = TButton->new(
    bounds  => TRect->new(ax => 19, ay => 8, bx => 31, by => 10),
    title   => '~C~ancel',
    command => cmCancel,
    flags   => bfNormal
  );

  $dialog->insert($ok);
  $dialog->insert($cancel);

  my $result = $deskTop->execView($dialog);

=head1 DESCRIPTION

C<TButton> implements an interactive pushbutton control with full TUI::Vision
semantics. It supports highlighting, shadow rendering, pressing behavior,
default-button logic, and command dispatch.

Mouse and keyboard events are handled according to the original Turbo Vision
model.

=head2 Commonly Used Features

Most applications use C<TButton> as a dialog control: create a button with
title/command/flags, insert it into a C<TDialog>, then react to the command
returned by C<execView()>. Typical setups include one default action button
(C<bfDefault>) and one normal cancel button (C<bfNormal>).

In day-to-day use you rarely call low-level methods directly; C<handleEvent()>,
C<draw()>, and default-button behavior are managed by the framework. Manual
calls to C<makeDefault()> are only needed for advanced dialog interactions
where default focus behavior is changed dynamically.

=head1 VARIABLES

The following global variables affect the visual rendering of C<TButton>.

=head2 $shadows

Defines the characters used to draw the button shadow.

=head2 $markers

Defines the characters used as button markers, for example C<[]>.

=head1 CONSTRUCTOR

=head2 new

  my $btn = TButton->new(
    bounds  => $bounds,
    title   => $title,
    command => $command,
    flags   => $flags
  );

Creates a new button control.

=over

=item bounds

The rectangular region defining the button's position (I<TRect>).

=item title

The caption displayed on the button, usually containing a hotkey marker
(I<Str>).

=item command

The command identifier broadcast when the button is pressed
(I<PositiveOrZeroInt>).

=item flags

Behavioral flags controlling default state, focus handling, and selection
(I<bfXXXX>).

=back

=head2 new_TButton

  my $btn = new_TButton($bounds, $title, $command, $flags);

Factory-style constructor using positional arguments.

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors.

=over

=item title

The caption displayed on the button (I<Str>).

=item command

The command identifier triggered when the button is pressed
(I<PositiveOrZeroInt>).

=item flags

Bit-mask of behavioral settings such as default, broadcast, or selectable
(I<PositiveOrZeroInt>).

=item amDefault

Boolean flag indicating whether the button is currently treated as the dialog's
default button (I<Bool>).

=back

=head1 METHODS

=head2 draw

  $btn->draw();

Renders the button according to its current state.

=head2 drawState

  $btn->drawState($down);

Draws the button in pressed or unpressed visual form.

=head2 getPalette

  my $palette = $btn->getPalette();

Returns the drawing palette for the button control.

=head2 handleEvent

  $btn->handleEvent($event);

Processes mouse clicks, key presses, and broadcast events for the button.

=head2 makeDefault

  $btn->makeDefault($enable);

Marks or unmarks the button as the dialog's default action button.

=head2 press

  $btn->press();

Sends the button's command to the dialog owner.

=head2 setState

  $btn->setState($state, $enable);

Updates the control's internal state and refreshes its appearance.

=head1 SEE ALSO

L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Label>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * Eric Woodruff

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 1995, 2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
