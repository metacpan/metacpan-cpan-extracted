package TUI::Gadgets::AsciiChart;
# ABSTRACT: window showing an ASCII table and the focused character

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TAsciiChart
  new_TAsciiChart
);

use Carp ();
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Drivers::Const qw( evBroadcast );
use TUI::Gadgets::Report;
use TUI::Gadgets::Table;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  ofFramed
  ofSelectable
  wfGrow
  wfZoom
  wnNoNumber
  wpGrayWindow
);
use TUI::Views::Window;

sub TAsciiChart() { __PACKAGE__ }
sub name() { 'TAsciiChart' }
sub new_TAsciiChart { __PACKAGE__->from(@_) }

extends TWindow;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method       => 1,
    named        => [],
    caller_level => +1,
  );
  my ( $class ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 0, ay => 0, bx => 34, by => 12 ),
    title  => 'ASCII Chart',
    number => wnNoNumber,
  );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  $self->{flags} &= ~( wfGrow | wfZoom );
  $self->{palette} = wpGrayWindow;

  my $r = $self->getExtent();
  $r->grow( -1, -1 );
  $r->{a}{y} = $r->{b}{y} - 1;
  my $report = TReport->new( bounds => $r );
  $report->{options}   |= ofFramed;
  $report->{eventMask} |= evBroadcast;
  $self->insert( $report );

  $r = $self->getExtent();
  $r->grow( -1, -1 );
  $r->{b}{y} -= 2;
  my $table = TTable->new( bounds => $r );
  $table->{options} |= ofFramed | ofSelectable;
  $table->blockCursor();
  $self->insert( $table );
  $table->select();
  return;
}

sub from {    # $asciiChart ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new();
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::AsciiChart - window with an ASCII table and character report

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TAsciiChart

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $chart = new_TAsciiChart();
  $deskTop->insert( $chart );

=head1 DESCRIPTION

C<TAsciiChart> is a fixed-size window titled C<ASCII Chart>. It contains a
L<TTable|TUI::Gadgets::Table> that shows the 256 characters of the character
set, and a L<TReport|TUI::Gadgets::Report> line that shows the code of the
focused character.

The window cannot be zoomed or resized and has no window number.

=head1 CONSTRUCTOR

=head2 new

  my $chart = TAsciiChart->new();

Creates a new ASCII chart window with the bounds C<(0, 0, 34, 12)>.

=head2 new_TAsciiChart

  my $chart = new_TAsciiChart();

Factory-style constructor without arguments.

=head1 SEE ALSO

L<TTable|TUI::Gadgets::Table>,
L<TReport|TUI::Gadgets::Report>,
L<TWindow|TUI::Views::Window>

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
