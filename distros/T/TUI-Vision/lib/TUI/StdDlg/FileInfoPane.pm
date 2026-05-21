package TUI::StdDlg::FileInfoPane;
# ABSTRACT: A view that displays the currently focused file in a file dialog

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileInfoPane
  new_TFileInfoPane
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Drivers::Const qw( evBroadcast );
use TUI::StdDlg::Const qw(
  cmFileFocused
  cpInfoPane
);
use TUI::StdDlg::FileCollection;
use TUI::StdDlg::Util qw( fexpand );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TFileInfoPane() { __PACKAGE__ }
sub name() { 'TFileInfoPane' }
sub new_TFileInfoPane { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $pmText = "p";
our $amText = "a";
our $months = [ '', qw(
  Jan Feb Mar Apr May Jun
  Jul Aug Sep Oct Nov Dec
)];

# private attributes
has file_block => ( 
  is => 'bare', 
  default => sub { TSearchRec->new(
    attr => 0,
    time => 0,
    size => 0,
    name => '',
  )}
);

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} |= evBroadcast;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $b = TDrawBuffer->new();

  # Prevents incorrect directory name display in info pane if wildCard
  # has already been expanded.
  my $path = $self->{owner}{wildCard};
  if ( $path !~ /[:\\]/ ) {
    $path = $self->{owner}{directory} . $self->{owner}{wildCard};
    fexpand( $path );
  }

  my $color = $self->getColor( 0x01 );
  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  $b->moveStr( 1, $path, $color );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  $b->moveStr( 1, $self->{file_block}->name, $color );

  if ( length $self->{file_block}->name ) {
    $b->moveStr( 14, $self->{file_block}->size, $color );

    my $time = $self->{file_block}->time;

    my $date16 = ( $time >> 16 ) & 0xFFFF;
    my $day    =   $date16         & 0x1F;
    my $month  = ( $date16 >> 5  ) & 0x0F;
    my $year   = ( $date16 >> 9  ) & 0x7F;

    $b->moveStr( 25, $months->[ $month ],     $color );
    $b->moveStr( 29, sprintf( "%02d", $day ), $color );
    $b->putChar( 31, ',' );
    $b->moveStr( 32, $year + 1980, $color );

    my $time16 =   $time         & 0xFFFF;
    my $min    = ( $time16 >> 5  ) & 0x3F;
    my $hour   = ( $time16 >> 11 ) & 0x1F;

    my $PM = $hour >= 12;
    my $hour12 = $hour % 12;
    $hour12 = 12 if $hour12 == 0;

    $b->moveStr( 38, sprintf( "%02d", $hour12 ), $color );
    $b->putChar( 40, ':' );
    $b->moveStr( 41, sprintf( "%02d", $min ), $color );
    $b->moveStr( 43, $PM ? $pmText : $amText, $color );
  } #/ if ( defined( $self->{file_block}...))

  $self->writeLine( 0, 1, $self->{size}{x}, 1, $b );
  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  $self->writeLine( 0, 2, $self->{size}{x}, $self->{size}{y} - 2, $b );

  return;
} #/ sub draw

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpInfoPane, 
    size => length( cpInfoPane ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmFileFocused
  ) {
    $self->{file_block} = $event->{message}{infoPtr};
    $self->drawView();
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FileInfoPane - view displaying information about the focused file

=head1 HIERARCHY

  TObject
    TView
      TFileInfoPane

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $info = new_TFileInfoPane(
    $bounds
  );

=head1 DESCRIPTION

C<TFileInfoPane> implements a view used by standard TUI::Vision file dialogs to
display information about the currently focused file or directory.

The pane renders metadata such as name, size, date, and attributes of the
active entry and updates its display automatically when the file selection
changes. It is typically embedded alongside a file list within a
C<TFileDialog>.

The view is display-only and does not allow direct user interaction.

=head1 VARIABLES

The following global variables define the textual and date-related
rendering used by C<TFileInfoPane>.

=head2 $pmText

Text used to indicate post meridiem (PM) time.

=head2 $amText

Text used to indicate ante meridiem (AM) time.

=head2 $months

Array reference containing abbreviated month names.
The first element is unused to allow 1-based month indexing.

=head1 CONSTRUCTOR

=head2 new

  my $pane = TFileInfoPane->new(
    bounds => $bounds
  );

Creates a new file information pane.

=over

=item bounds

Bounding rectangle defining the position and size of the pane (I<TRect>).

=back

=head2 new_TFileInfoPane

  my $pane = new_TFileInfoPane($bounds);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $pane->draw();

Renders the file information pane.

This method draws the textual representation of the currently focused file
using an internal draw buffer.

=head2 getPalette

  my $palette = $pane->getPalette();

Returns the palette used for rendering the file information pane.

=head2 handleEvent

  $pane->handleEvent($event);

Processes events relevant to updating the displayed file information.

The pane reacts to selection and focus changes originating from other dialog
components.

=head1 SEE ALSO

L<TUI::StdDlg::FileDialog>,
L<TUI::StdDlg::FileList>,
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
