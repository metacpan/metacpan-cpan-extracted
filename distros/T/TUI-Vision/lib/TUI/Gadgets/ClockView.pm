package TUI::Gadgets::ClockView;
# ABSTRACT: clock view which display the clock

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TClockView
  new_TClockView
);

use POSIX qw( strftime );
use TUI::toolkit;
use TUI::toolkit::Types qw( :Object );

use TUI::Views::DrawBuffer;
use TUI::Views::View;

sub TClockView() { __PACKAGE__ }
sub name() { 'TClockView' }
sub new_TClockView { __PACKAGE__->from(@_) }

extends TView;

# private attributes
has lastTime => ( is => 'bare' );
has curTime  => ( is => 'bare' );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{lastTime} = "        ";
  $self->{curTime}  = "        ";
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $buf = TDrawBuffer->new();
  my $c   = $self->getColor( 2 );

  $buf->moveChar( 0, ' ', $c, $self->{size}{x} );
  $buf->moveStr( 0, $self->{curTime}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
} #/ sub draw

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  $self->{curTime} = strftime( '%H:%M:%S', localtime );

  if ( $self->{lastTime} ne $self->{curTime} ) {
    $self->{lastTime} = $self->{curTime};
    $self->drawView();
  }
  return;
} #/ sub update

1

__END__

=pod

=head1 NAME

TUI::Gadgets::ClockView - view displaying the current time

=head1 HIERARCHY

  TObject
    TView
      TClockView

=head1 SYNOPSIS

  use TUI::Gadgets;

  my $clock = new_TClockView(
    $bounds
  );

=head1 DESCRIPTION

C<TClockView> implements a view that displays the current system time.

The view periodically updates its display to reflect changes in the current
time and renders a textual clock representation. It is intended as a small
informational gadget and is typically embedded in status views or diagnostic
layouts.

=head1 CONSTRUCTOR

=head2 new

  my $view = TClockView->new(
    bounds => $bounds
  );

Creates a new clock view.

=over

=item bounds

Bounding rectangle defining the position and size of the view (I<TRect>).

=back

=head2 new_TClockView

  my $view = new_TClockView($bounds);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $view->draw();

Renders the current time.

=head2 update

  $view->update();

Updates the internal time state and refreshes the display if the time has
changed.

=head1 SEE ALSO

L<TUI::Views::View>,
L<TUI::Views::DrawBuffer>

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
