package TUI::Dialogs::HistoryWindow;
# ABSTRACT: Window component showing and managing history list items

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistoryWindow
  new_THistoryWindow
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types  qw(
  :is
  :types
);

use TUI::Dialogs::Const qw( cpHistoryWindow );
use TUI::Dialogs::HistInit;
use TUI::Dialogs::HistoryViewer;
use TUI::Views::Const qw(
  sbHandleKeyboard
  sbHorizontal
  sbVertical
  wfClose
  wnNoNumber
);
use TUI::Views::Palette;
use TUI::Views::Window;

sub THistoryWindow() { __PACKAGE__ }
sub new_THistoryWindow { __PACKAGE__->from(@_) }

extends ( TWindow, THistInit );

# protected attributes
has viewer => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds    => Object,
      historyId => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = TWindow->BUILDARGS(
    bounds => $args1->{bounds},
    title  => '',
    number => wnNoNumber,
  );
  my $args3 = THistInit->BUILDARGS(
    cListViewer => $class->can( 'initViewer' )
  );
  return { %$args1, %$args2, %$args3 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{flags} = wfClose;
  if ( $self->{createListViewer} ) {
    $self->{viewer} = $self->createListViewer( $self->getExtent(), $self, 
      $args->{historyId} );
    $self->insert( $self->{viewer} ) if $self->{viewer};
  }
  return;
}

sub from {    # $obj ($bounds, $historyId)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], historyId => $args[1] );
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpHistoryWindow, 
    size => length( cpHistoryWindow ),
  );
  return $palette->clone();
}

sub getSelection {    # void (\$dest)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef],
  );
  my ( $self, $dest ) = @_;
  $self->{viewer}->getText( $dest, $self->{viewer}{focused}, 255 );
  return;
}

sub initViewer {    # $listViewer ($r, $win, $historyId)
  state $sig = signature(
    method => 1,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $class, $r, $win, $historyId ) = $sig->( @_ );
  $r->grow( -1, -1 );
  return THistoryViewer->new(
    bounds     => $r,
    hScrollBar => $win->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
    vScrollBar => $win->standardScrollBar( sbVertical | sbHandleKeyboard ),
    historyId  => $historyId,
  );
} #/ sub initViewer

1

__END__

=pod

=head1 NAME

TUI::Dialogs::HistoryWindow - window displaying input history entries

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          THistoryWindow

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $window = TUI::Dialogs::HistoryWindow->new(
    bounds    => $bounds,
    historyId => 1
  );

=head1 DESCRIPTION

C<THistoryWindow> implements the window used to display the history list managed
by C<THistory>. When the history icon is activated, a history window is created
and populated with a list viewer showing previously entered values.

This class primarily exists to support the internal operation of history lists
and is not commonly instantiated directly by application code. The window owns
a C<THistoryViewer> instance that handles rendering and selection of history
entries.

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item viewer

Reference to the history list viewer (I<THistoryViewer>) contained within this
window.

=back

=head1 CONSTRUCTOR

=head2 new

  my $window = THistoryWindow->new(
    bounds    => $bounds,
    historyId => $historyId
  );

Creates a new history window and initializes its internal list viewer.

=over

=item bounds

Bounding rectangle of the history window (I<TRect>).

=item historyId

Numeric identifier selecting which history list is displayed.

=back

=head2 new_THistoryWindow

  my $window = new_THistoryWindow($bounds, $historyId);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 getPalette

  my $palette = $window->getPalette();

Returns the color palette used to draw the history window.

=head2 getSelection

  $window->getSelection(\$dest);

Copies the currently selected history entry into C<$dest>.

=head2 initViewer

  my $viewer = $window->initViewer($rect, $window, $historyId);

Creates and initializes the internal history list viewer.

=head1 SEE ALSO

L<TUI::Dialogs::History>,
L<TUI::Dialogs::HistoryViewer>,
L<TUI::Dialogs::InputLine>

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
