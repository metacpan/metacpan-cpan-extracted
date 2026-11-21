package TUI::Gadgets::Report;
# ABSTRACT: status line view displaying the character focused in an ASCII table

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TReport
  new_TReport
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :Object );

use TUI::Drivers::Const qw( evBroadcast );
use TUI::Gadgets::Const qw(
  cmAsciiTableCmdBase
  cmCharFocused
);
use TUI::Views::DrawBuffer;
use TUI::Views::View;

sub TReport() { __PACKAGE__ }
sub name() { 'TReport' }
sub new_TReport { __PACKAGE__->from(@_) }

extends TView;

# private attributes
has asciiChar => ( is => 'bare', default => 0 );

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $buf   = TDrawBuffer->new();
  my $color = $self->getColor( 6 );
  my $code  = $self->{asciiChar};
  my $char  = $code == 0 ? ' ' : chr( $code );
  my $str   = sprintf( "  Char: %s Decimal: %3d Hex %2X     ",
    $char, $code, $code );

  $buf->moveStr( 0, $str, $color );
  $self->writeLine( 0, 0, 32, 1, $buf );
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmAsciiTableCmdBase + cmCharFocused
  ) {
    $self->{asciiChar} = $event->{message}{infoLong};
    $self->drawView();
  }
  return;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put( $self->{asciiChar} );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{asciiChar} = $is->get();
  return $self;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::Report - status line for the focused ASCII character

=head1 HIERARCHY

  TObject
    TView
      TReport

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $report = TReport->new(
    bounds => TRect->new( ax => 1, ay => 9, bx => 33, by => 10 ),
  );
  $window->insert( $report );

=head1 DESCRIPTION

C<TReport> is a single-line view that shows the character code of the
character currently focused in a L<TTable|TUI::Gadgets::Table>. It displays
the character itself, its decimal code and its hexadecimal code, for example
C<  Char: A Decimal: 065 Hex 41>.

The view reacts to the C<cmCharFocused> broadcast of a table. It must
receive broadcasts, so the owner of the view has to set the C<evBroadcast>
bit in its C<eventMask>, as L<TAsciiChart|TUI::Gadgets::AsciiChart> does.

=head1 CONSTRUCTOR

=head2 new

  my $report = TReport->new( bounds => $bounds );

Creates a new report view. The initial character code is 0.

=over

=item bounds

Bounding rectangle defining the position and size of the view
(L<TRect|TUI::Objects::Rect>).

=back

=head2 new_TReport

  my $report = new_TReport( $bounds );

Factory-style constructor using a positional bounds argument.

=head1 METHODS

=head2 draw

  $report->draw();

Draws the status text for the current character code.

=head2 handleEvent

  $report->handleEvent( $event );

Stores the character code from a C<cmCharFocused> broadcast and redraws the
view.

=head1 SEE ALSO

L<TAsciiChart|TUI::Gadgets::AsciiChart>,
L<TTable|TUI::Gadgets::Table>,
L<TView|TUI::Views::View>

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
