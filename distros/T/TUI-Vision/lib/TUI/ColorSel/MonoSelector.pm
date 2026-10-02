package TUI::ColorSel::MonoSelector;
# ABSTRACT: A selector for monochrome attributes. 

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMonoSelector
  new_TMonoSelector
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Drivers::Const qw( evBroadcast );
use TUI::Dialogs::Cluster;
use TUI::Dialogs::StrItem;
use TUI::ColorSel::Const qw( :cmXXXX );
use TUI::Views::Util qw( message );

sub TMonoSelector() { __PACKAGE__ }
sub name() { 'TMonoSelector' }
sub new_TMonoSelector { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare global variables
our $button    = " ( ) ";
our $normal    = "Normal";
our $highlight = "Highlight";
our $underline = "Underline";
our $inverse   = "Inverse";

# lookup table of monochrome color values
my @monoColors = ( 0x07, 0x0f, 0x01, 0x70, 0x09 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds  => $args1->{bounds},
    strings => new_TSItem( $normal,
               new_TSItem( $highlight,
               new_TSItem( $underline,
               new_TSItem( $inverse, undef )))),
  );
  return { %$args1, %$args2 };
}

sub from {    # $obj ($bounds)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $bounds ) = $sig->( @_ );
  return $class->new( bounds => $bounds );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawBox( $button, "\x7" );
  return;
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
    && $event->{message}{command} == cmColorSet
  ) {
    $self->{value} = $event->{message}{infoByte};
    $self->drawView();
  }
  return;
}

sub mark {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $monoColors[$item] == $self->{value};
}

sub newColor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  message( $self->{owner}, evBroadcast, cmColorForegroundChanged, 
    $self->{value} & 0x0f );
  message( $self->{owner}, evBroadcast, cmColorBackgroundChanged, 
    ( $self->{value} >> 4 ) & 0x0f );
  return;
}

sub press {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{value} = $monoColors[$item];
  $self->newColor();
  return;
}

sub movedTo {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{value} = $monoColors[$item];
  $self->newColor();
  return;
}

1

__END__

=pod

=head1 NAME

TUI::ColorSel::MonoSelector - monochrome attribute selector control

=head1 HIERARCHY

  TObject
    TView
      TCluster
        TMonoSelector

=head1 SYNOPSIS

  use TUI::ColorSel;
  use TUI::Objects;

  my $bounds = TRect->new(
    ax => 0,
    ay => 0,
    bx => 20,
    by => 5
  );

  my $selector = TMonoSelector->new(
    bounds => $bounds
  );

  $dialog->insert( $selector );

=head1 DESCRIPTION

C<TMonoSelector> implements a monochrome attribute selector based on the
standard L<TCluster|TUI::Dialogs::Cluster> control.

The selector presents a fixed set of monochrome display attributes and
allows the user to choose between them. The available selections correspond
to the classic I<Turbo Vision> monochrome display modes.

Whenever the selected attribute changes, the selector broadcasts the
corresponding foreground and background colors so that related controls may
update themselves automatically.

=head2 Commonly Used Features

Applications typically create a C<TMonoSelector>, insert it into a dialog,
and allow the dialog event loop to manage user interaction.

The control synchronizes itself with C<cmColorSet> broadcasts and emits
C<cmColorForegroundChanged> and C<cmColorBackgroundChanged> messages when
the selected monochrome attribute changes.

=head1 VARIABLES

The following global variables define the labels and visual appearance of
the selector.

=head2 $button

Defines the marker pattern (I<Str>) used when drawing an item.

=head2 $normal

Label used for the normal attribute entry (I<Str>).

=head2 $highlight

Label used for the highlight attribute entry (I<Str>).

=head2 $underline

Label used for the underline attribute entry (I<Str>).

=head2 $inverse

Label used for the inverse attribute entry (I<Str>).

=head1 CONSTRUCTOR

=head2 new

  my $selector = TMonoSelector->new( bounds => $bounds );

Creates a new monochrome selector.

=over

=item bounds

Bounding rectangle defining the position and size of the selector 
(L<TRect|TUI::Objects::Rect>).

=back

=head2 new_TMonoSelector

  my $selector = new_TMonoSelector( $bounds );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $selector->draw();

Draws the monochrome selector using the standard cluster layout.

=head2 handleEvent

  $selector->handleEvent( $event );

Handles broadcast events.

The selector responds to C<cmColorSet> broadcasts and updates its current
attribute accordingly.

=head2 mark

  my $bool = $selector->mark( $item );

Returns true if the specified item corresponds to the currently selected
monochrome attribute.

=head2 movedTo

  $selector->movedTo( $item );

Updates the selected attribute when the selection cursor moves to a different 
item.

=head2 newColor

  $selector->newColor();

Broadcasts the foreground (C<cmColorForegroundChanged>) and background 
(C<cmColorBackgroundChanged>) colors corresponding to the currently selected 
monochrome attribute.

=head2 press

  $selector->press( $item );

Selects the specified monochrome attribute.

=head1 SEE ALSO

L<TColorDialog|TUI::ColorSel::ColorDialog>,
L<TCluster|TUI::Dialogs::Cluster>,
L<TColorSelector|TUI::ColorSel::ColorSelector>

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
