package TUI::Editors::EditWindow;
# ABSTRACT: TEditWindow is a window that hosts a file editor.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TEditWindow
  new_TEditWindow
);

use Carp ();
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  is_Str
  :types
);

use TUI::Drivers::Const qw( :evXXXX );
use TUI::Drivers::Event;
use TUI::Editors::Const qw( :cmXXXX );
use TUI::Editors::FileEditor;
use TUI::Editors::Indicator;
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw( ofTileable );
use TUI::Views::ScrollBar;
use TUI::Views::Window;

sub TEditWindow() { __PACKAGE__ }
sub name() { 'TEditWindow' }
sub new_TEditWindow { __PACKAGE__->from(@_) }

extends TWindow;

# declare global variables
our $clipboardTitle = 'Clipboard';
our $untitled       = 'Untitled';

# public attributes
has editor => ( is => 'rw' );

# declare local variables
my $minEditWinSize = TPoint->new( x => 24, y => 6 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds   => Object,
      fileName => Maybe[Str], { alias => 'aFileName' },
      number   => Int,        { alias => 'aNumber'   },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => $args1->{bounds},
    title  => '',
    number => $args1->{number},
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{options} |= ofTileable;

  my $size = $self->{size};
  my $hScrollBar = TScrollBar->new(
    bounds => TRect->new(
      ax => 18,
      ay => $size->{y} - 1,
      bx => $size->{x} - 2,
      by => $size->{y},
    ),
  );
  $hScrollBar->hide();
  $self->insert( $hScrollBar );

  my $vScrollBar = TScrollBar->new(
    bounds => TRect->new(
      ax => $size->{x} - 1,
      ay => 1,
      bx => $size->{x},
      by => $size->{y} - 1,
    ),
  );
  $vScrollBar->hide();
  $self->insert( $vScrollBar );

  my $indicator = TIndicator->new(
    bounds => TRect->new(
      ax => 2,
      ay => $size->{y} - 1,
      bx => 16,
      by => $size->{y},
    ),
  );
  $indicator->hide();
  $self->insert( $indicator );

  my $r = $self->getExtent();
  $r->grow( -1, -1 );
  $self->{editor} = TFileEditor->new(
    bounds     => $r,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar,
    indicator  => $indicator,
    fileName   => $args->{fileName},
  );
  $self->insert( $self->{editor} );
  return;
}

sub from {    # $obj ($bounds, $aFileName|undef, $aNumber)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Str], Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], fileName => $args[1], 
    number => $args[2] );
}

sub close {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{editor}->isClipboard() ) {
    $self->hide();
  }
  else {
    $self->SUPER::close();
  }
  return;
}

sub getTitle {    # $str ($maxSize)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $maxSize ) = $sig->( @_ );
  return $clipboardTitle
    if $self->{editor}->isClipboard();
  my $fileName = $self->{editor}{fileName};
  return length $fileName ? $fileName : $untitled;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmUpdateTitle
  ) {
    $self->{frame}->drawView() if $self->{frame};
    $self->clearEvent( $event );
  }
  return;
}

sub sizeLimits {    # void ($min, $max)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object],
  );
  my ( $self, $min, $max ) = $sig->( @_ );
  alias: for $min ( $_[1] ) {
  alias: for $max ( $_[2] ) {
  $self->SUPER::sizeLimits( $min, $max );
  $min = $minEditWinSize->clone();
  return;
  }} #/ alias:
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put( $self->{editor} );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{editor} = $is->get();
  return $self;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds   => TRect->new(),
    fileName => '',
    number   => 0,
  );
}

1

__END__

=pod

=head1 NAME

TUI::Editors::EditWindow - window that hosts a file editor

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TEditWindow

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;

  my $r = TRect->new( ax => 0, ay => 0, bx => 60, by => 20 );
  my $w = new_TEditWindow( $r, 'notes.txt', 1 );
  $deskTop->insert( $w );

=head1 DESCRIPTION

C<TEditWindow> is a L<TWindow|TUI::Views::Window> that contains a
L<TFileEditor|TUI::Editors::FileEditor> together with horizontal and vertical
scrollbars and an L<TIndicator|TUI::Editors::Indicator>. The scrollbars and the
indicator are created hidden; the editor shows them when it needs them.

The window is marked as tileable and has a minimum size of 24 x 6. Its title
is the file name of the editor, C<Untitled> if the editor has no file name, or
C<Clipboard> if the editor is the clipboard. Closing the window that shows the
clipboard hides it instead of closing it.

=head1 VARIABLES

The following global variables define the window titles of C<TEditWindow>.

=head2 $clipboardTitle

The title shown for a window whose editor is the clipboard. Defaults to
C<'Clipboard'>.

=head2 $untitled

The title shown for a window whose editor has no file name. Defaults to
C<'Untitled'>.

=head1 ATTRIBUTES

=head2 editor

  my $editor = $w->editor;

The L<TFileEditor|TUI::Editors::FileEditor> contained in the window.

=head1 CONSTRUCTOR

=head2 new

  my $w = TEditWindow->new(
    bounds   => $bounds,
    fileName => $fileName,
    number   => $number,
  );

Creates a new edit window and inserts a
L<TFileEditor|TUI::Editors::FileEditor> that loads the specified file.

=over

=item bounds

The bounds of the window (I<Object>, a L<TRect|TUI::Objects::Rect>).

=item fileName

The name of the file to edit (I<Str> or I<undef>). An empty or undefined file
name creates an untitled editor.

=item number

The window number (I<Int>).

=back

=head2 new_TEditWindow

  my $w = new_TEditWindow( $bounds, $fileName, $number );

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and
is provided for compatibility with traditional I<Turbo Vision> construction
patterns.

=head1 METHODS

=head2 close

  $w->close;

Hides the window if its editor is the clipboard. Otherwise closes the window
as L<TWindow|TUI::Views::Window> does.

=head2 getTitle

  my $title = $w->getTitle( $maxSize );

Returns C<Clipboard> for the clipboard editor, C<Untitled> for an editor
without a file name, and the file name otherwise.

=head2 handleEvent

  $w->handleEvent( $event );

Handles the window events as L<TWindow|TUI::Views::Window> does. A
C<cmUpdateTitle> broadcast redraws the frame so that the new title is shown,
and the event is cleared.

=head2 sizeLimits

  $w->sizeLimits( $min, $max );

Sets the minimum size of the window to 24 x 6.

=head1 SEE ALSO

L<TFileEditor|TUI::Editors::FileEditor>,
L<TWindow|TUI::Views::Window>,
L<TIndicator|TUI::Editors::Indicator>,
L<TScrollBar|TUI::Views::ScrollBar>

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
