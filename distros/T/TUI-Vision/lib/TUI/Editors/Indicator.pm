package TUI::Editors::Indicator;
# ABSTRACT: indicator view which displays the editor cursor position

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TIndicator
  new_TIndicator
);

use Encode qw( encode );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Editors::Const qw( cpIndicator );
use TUI::Objects::Point;
use TUI::Views::Const qw(
  gfGrowHiY
  gfGrowLoY
  sfDragging
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TIndicator() { __PACKAGE__ }
sub name() { 'TIndicator' }
sub new_TIndicator { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $dragFrame   = encode( cp437 => "═" );
our $normalFrame = encode( cp437 => "─" );

# protected attributes
has location => ( is => 'ro', default => sub { TPoint->new } );
has modified => ( is => 'ro', default => false );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{growMode} = gfGrowLoY | gfGrowHiY;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my ( $color, $frame );
  if ( ( $self->{state} & sfDragging ) == 0 ) {
    $color = $self->getColor( 1 );
    $frame = $dragFrame;
  }
  else {
    $color = $self->getColor( 2 );
    $frame = $normalFrame;
  }

  my $b = TDrawBuffer->new();
  $b->moveChar( 0, $frame, $color, $self->{size}{x} );
  $b->putChar( 0, chr( 15 ) ) if $self->{modified};

  # Borland's C++ implementation buffer of 15 bytes holds at most 14 characters
  my $s = substr(
    sprintf( ' %d:%d ', $self->{location}{y} + 1, $self->{location}{x} + 1 ),
    0, 14
  );
  $b->moveCStr( 8 - index( $s, ':' ), $s, $color );
  $self->writeBuf( 0, 0, $self->{size}{x}, 1, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpIndicator,
    size => length( cpIndicator ),
  );
  return $palette->clone();
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfDragging ) {
    $self->drawView();
  }
  return;
}

sub setValue {    # void ($aLocation, $aModified)
  state $sig = signature(
    method => Object,
    pos    => [Object, Bool],
  );
  my ( $self, $aLocation, $aModified ) = $sig->( @_ );
  if ( $self->{location} != $aLocation || $self->{modified} != $aModified ) {
    $self->{location} = $aLocation->clone();
    $self->{modified} = $aModified;
    $self->drawView();
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Editors::Indicator - indicator which displays the editor cursor position

=head1 HIERARCHY

  TObject
    TView
      TIndicator

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;
  use TUI::toolkit;

  my $indicator = new_TIndicator( $bounds );
  $indicator->setValue( TPoint->new(), false );

=head1 DESCRIPTION

C<TIndicator> is a one-line view that displays the current cursor position of
an editor as C<line:column> (both one-based). If the editor contents have been
modified, a modification marker is shown at the left edge of the view.

While the owning view is being dragged, the frame at the left edge is drawn
with a different glyph and color, as in the original I<Turbo Vision> indicator.

The view grows vertically with its owner's bottom edge, so it keeps its
height when the owner is resized.

=head1 VARIABLES

The following global variables define the frame glyphs of C<TIndicator>.

=head2 $dragFrame

Drag frame drawing character.

=head2 $normalFrame

Normal frame drawing character.

=head1 CONSTRUCTOR

=head2 new

  my $view = TIndicator->new(
    bounds => $bounds
  );

Creates a new indicator view with the cursor at position C<0,0> and the
modified flag cleared.

=over

=item bounds

Bounding rectangle defining the position and size of the view
(L<TRect|TUI::Objects::Rect>).

=back

=head2 new_TIndicator

  my $view = new_TIndicator($bounds);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $view->draw();

Renders the frame, the modification marker and the cursor position.

=head2 getPalette

  my $palette = $view->getPalette();

Returns the palette used by the indicator (L<TPalette|TUI::Views::Palette>).

=head2 setState

  $view->setState( $aState, $enable );

Calls the inherited C<setState> and redraws the view when C<sfDragging> is set
or cleared.

=head2 setValue

  $view->setValue( $aLocation, $aModified );

Updates the displayed cursor position and modified flag. The view is redrawn
only if one of them has changed.

=over

=item aLocation

The cursor position as L<TPoint|TUI::Objects::Point>, zero-based.

=item aModified

True if the editor contents have been modified.

=back

=head1 SEE ALSO

L<TUI::Editors>,
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
