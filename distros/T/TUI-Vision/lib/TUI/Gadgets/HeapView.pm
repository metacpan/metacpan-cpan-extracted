package TUI::Gadgets::HeapView;
# ABSTRACT: heap view which display the current heap space

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THeapView
  new_THeapView
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :Object );

use TUI::Views::DrawBuffer;
use TUI::Views::View;

sub THeapView() { __PACKAGE__ }
sub name() { 'THeapView' }
sub new_THeapView { __PACKAGE__->from(@_) }

extends TView;

# private attributes
has oldMem  => ( is => 'bare' );
has newMem  => ( is => 'bare' );
has heapStr => ( is => 'bare' );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{oldMem} = 0;
  $self->{newMem} = $self->heapSize();
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
  $buf->moveStr( 0, $self->{heapStr}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
} #/ sub draw

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  if ( ( $self->{newMem} = $self->heapSize() ) != $self->{oldMem} ) {
    $self->{oldMem} = $self->{newMem};
    $self->drawView();
  }
  return;
} #/ sub update

sub heapSize {    # $total ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  if ( $^O eq 'MSWin32' ) {
    require TUI::Gadgets::HeapView::Win32;
    goto &TUI::Gadgets::HeapView::Win32::heapSize;
  }
  return -1;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::HeapView - view displaying current heap usage

=head1 HIERARCHY

  TObject
    TView
      THeapView

=head1 SYNOPSIS

  use TUI::Gadgets;

  my $heapView = new_THeapView(
    $bounds
  );

=head1 DESCRIPTION

C<THeapView> implements a view that displays information about the current heap
usage of the application.

The view periodically samples heap statistics and renders a textual
representation of used and available memory. It is intended as a diagnostic
gadget and is typically embedded in status views or debugging layouts.

=head1 CONSTRUCTOR

=head2 new

  my $view = THeapView->new(
    bounds => $bounds
  );

Creates a new heap view.

=over

=item bounds

Bounding rectangle defining the position and size of the view (I<TRect>).

=back

=head2 new_THeapView

  my $view = new_THeapView($bounds);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $view->draw();

Renders the heap usage information.

=head2 heapSize

  my $total = $view->heapSize();

Returns the total heap size currently available to the application.

=head2 update

  $view->update();

Refreshes the internal heap statistics and updates the display.

=head1 SEE ALSO

L<TUI::Views::HelpView::Win32>,
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

