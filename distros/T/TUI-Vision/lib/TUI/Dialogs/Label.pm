package TUI::Dialogs::Label;
# ABSTRACT: Provides a descriptive label linked to another dialog control.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TLabel
  new_TLabel
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Dialogs::Const qw( cpLabel );
use TUI::Dialogs::StaticText;
use TUI::Dialogs::Util qw( hotKey );
use TUI::Drivers::Const qw(
  :evXXXX
);
use TUI::Drivers::Util qw(
  cstrlen
  getAltCode
);
use TUI::Views::Const qw(
  cmReceivedFocus
  cmReleasedFocus
  :ofXXXX
  phPostProcess
  sfFocused
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TLabel() { __PACKAGE__ }
sub name() { 'TLabel' }
sub new_TLabel { __PACKAGE__->from(@_) }

extends TStaticText;

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

# protected attributes
has link  => ( is => 'ro', default => sub { die 'required' } );
has light => ( is => 'ro', default => false );

# predeclare private methods
my (
  $focusLink,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      text   => Str,           { alias => 'aText' },
      link   => Maybe[Object], { alias => 'aLink' },
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
  $self->{options} |= ofPreProcess | ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aText, $aLink|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], text => $args[1], link => $args[2] );
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{link} = undef;
  $self->SUPER::shutDown();
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $color;
  my $b = TDrawBuffer->new();
  my $scOff;

  if ( $self->{light} ) {
    $color = $self->getColor( 0x0402 );
    $scOff = 0;
  }
  else {
    $color = $self->getColor( 0x0301 );
    $scOff = 4;
  }

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  if ( $self->{text} ) {
    $b->moveCStr( 1, $self->{text}, $color );
  }
  if ( $showMarkers ) {
    $b->putChar( 0, $specialChars->[$scOff] );
  }
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new( data => cpLabel, size => length( cpLabel ) );
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
  if ( $event->{what} == evMouseDown ) {
    $self->$focusLink( $event );
  }
  elsif ( $event->{what} == evKeyDown ) {
    my $c = hotKey( $self->{text} );
    if (
      getAltCode( $c ) == $event->{keyDown}{keyCode}
      || ( $c
        && $self->{owner}{phase} == phPostProcess
        && uc( $event->{keyDown}{charScan}{charCode} ) eq $c )
    ) {
      $self->$focusLink( $event );
    }
  } #/ elsif ( $event->{what} ==...)
  elsif (
    $event->{what} == evBroadcast && $self->{link}
    && ( $event->{message}{command} == cmReceivedFocus
      || $event->{message}{command} == cmReleasedFocus )
  ) {
    $self->{light} = ( $self->{link}{state} & sfFocused ) != 0;
    $self->drawView();
  } #/ elsif ( $event->{what} ==...)
  return;
} #/ sub handleEvent

$focusLink = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  if ( $self->{link} && ( $self->{link}{options} & ofSelectable ) ) {
    $self->{link}->focus();
  }
  $self->clearEvent( $event );
  return;
};

1

__END__

=pod

=head1 NAME

TUI::Dialogs::Label - descriptive label linked to another dialog control

=head1 HIERARCHY

  TObject
    TView
      TStaticText
        TLabel

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $label = TLabel->new(
    bounds => $bounds,
    text   => '~N~ame:',
    link   => $inputLine
  );

=head1 DESCRIPTION

C<TLabel> represents a static text label that is explicitly linked to another
dialog control. Unlike C<TStaticText>, a label forwards activation events to
its linked control, allowing users to focus or activate that control by
clicking the label or using a keyboard shortcut.

Hotkey activation is supported through marked characters in the label text.
When the corresponding key combination is pressed, focus is transferred to the
linked control.

Labels are typically used as prompts for input fields, list boxes, or other
dialog elements and are commonly paired with controls such as C<TInputLine> or
radio button groups.

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors and are managed
internally by the label implementation.

=over

=item link

Reference to the control associated with this label (I<TView>).  
If set, activation of the label selects the linked control.

=item light

Indicates whether the label is currently displayed in its highlighted variant
(I<Bool>). This state is managed internally.

=back

=head1 CONSTRUCTOR

=head2 new

  my $label = TLabel->new(
    bounds => $bounds,
    text   => $text,
    link   => $link
  );

Creates a new label with the specified bounds, text, and optional link target.

=over

=item bounds

Bounding rectangle of the label (I<TRect>).

=item text

Text displayed by the label. Marked characters may be used to define a hotkey
(I<Str>).

=item link

Optional control that receives focus when the label is activated
(I<TView>). This parameter may be omitted.

=back

=head2 new_TLabel

  my $label = new_TLabel($bounds, $text, | $link);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 draw

  $label->draw();

Draws the label using the palette returned by C<getPalette> and renders any
hotkey markers.

=head2 getPalette

  my $palette = $label->getPalette();

Returns the color palette used to draw the label.

=head2 handleEvent

  $label->handleEvent($event);

Processes mouse and keyboard events. Activation events are forwarded to the
linked control, if present.

=head2 shutDown

  $label->shutDown();

Releases internal references during shutdown.

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
