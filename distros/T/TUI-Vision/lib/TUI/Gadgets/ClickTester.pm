package TUI::Gadgets::ClickTester;
# ABSTRACT: A mouse clickable tester gadget for the framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TClickTester
  new_TClickTester
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Drivers::Const qw(
  evMouseDown
  meDoubleClick
);
use TUI::Dialogs::StaticText;
use TUI::Gadgets::Const qw( cpMousePalette );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;

sub TClickTester() { __PACKAGE__ }
sub new_TClickTester { __PACKAGE__->from(@_) }

extends TStaticText;

# private attributes
has clicked => ( is => 'bare', default => false );

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpMousePalette, 
    size => length( cpMousePalette ),
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

  if ( $event->{what} == evMouseDown ) {
    if ( $event->{mouse}{eventFlags} & meDoubleClick ) {
      $self->{clicked} = !$self->{clicked};
      $self->drawView();
    }
    $self->clearEvent( $event );
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $buf = TDrawBuffer->new();
  my $c = $self->{clicked}
        ? $self->getColor( 2 )
        : $self->getColor( 1 );

  $buf->moveChar( 0, ' ', $c, $self->{size}{x} );
  $buf->moveStr( 0, $self->{text}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::ClickTester - mouse click test gadget

=head1 HIERARCHY

  TObject
    TView
      TStaticText
        TClickTester

=head1 SYNOPSIS

  use TUI::Objects::Rect;
  use TUI::Gadgets::ClickTester;

  my $bounds = TRect->new( 0, 0, 20, 3 );
  my $view = TClickTester->new(
    bounds => $bounds,
    text   => 'Double-click here',
  );
  $dialog->insert( $view );

=head1 DESCRIPTION

C<TClickTester> is a small diagnostic view used for testing mouse support.

The view displays a text label and changes its visual state whenever it
receives a double-click mouse event. It can be used to verify that mouse
events are delivered correctly by the application and terminal backend.

=head1 CONSTRUCTOR

=head2 new

  my $view = TClickTester->new(
    bounds => $bounds,
    text   => 'Double-click here',
  );

Creates a new click tester view.

=over

=item bounds

Bounding rectangle defining the position and size of the view 
(L<TRect|TUI::Objects::Rect>).

=item text

Text displayed by the view (I<Str>).

=back

=head2 new_TClickTester

  my $view = new_TClickTester( $bounds, 'Double-click here' );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $view->draw();

Draws the view using a color that reflects the current click state.

=head2 handleEvent

  $view->handleEvent($event);

Processes mouse events and toggles the visual state when a double-click
is received.

=head1 SEE ALSO

L<TMouseDialog|TUI::Gadgets::MouseDialog>,
L<TStaticText|TUI::Dialogs::StaticText>

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
