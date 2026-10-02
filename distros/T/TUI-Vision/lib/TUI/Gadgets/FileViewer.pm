package TUI::Gadgets::FileViewer;
# ABSTRACT: File viewer gadget for TUI::Vision applications

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileViewer
  new_TFileViewer
);

use Carp ();
use IO::File;
use List::Util qw( max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Const qw( EOS );
use TUI::Gadgets::Const qw( maxLineLength );
use TUI::Gadgets::LineCollection;
use TUI::Memory qw( lowMemory );
use TUI::MsgBox::Const qw( :mfXXXX );
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Views::Const qw(
  gfGrowHiX
  gfGrowHiY
  sfExposed
);
use TUI::Views::DrawBuffer;
use TUI::Views::Scroller;

sub TFileViewer() { __PACKAGE__ }
sub name() { 'TFileViewer' }
sub new_TFileViewer { __PACKAGE__->from(@_) }

extends TScroller;

# public attributes
has fileName  => ( is => 'rw', default => sub { die 'required' } );
has fileLines => ( is => 'rw' );
has isValid   => ( is => 'rw', default => !!0 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
      fileName   => Str,           { alias => 'aFileName'   },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    hScrollBar => $args1->{hScrollBar},
    vScrollBar => $args1->{vScrollBar},
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{growMode} |= gfGrowHiX | gfGrowHiY;
  $self->{isValid} = true;
  $self->{fileName} = '';
  $self->readFile( $args->{fileName} );
  return;
}

sub from {    # $fileView ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, $aFileName)
  state $sig = signature(
    method => 1,
    pos => [Object, Maybe[Object], Maybe[Object], Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1], 
    vScrollBar => $args[2], fileName => $args[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  undef $self->{fileName};
  $self->destroy( $self->{fileLines} );
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $p;

  my $c = $self->getColor( 0x0301 );
  for ( my $i = 0 ; $i < $self->{size}{y} ; $i++ ) {
    my $b = TDrawBuffer->new();
    $b->moveChar( 0, ' ', $c, $self->{size}{x} );
    if ( $self->{delta}{y} + $i < $self->{fileLines}->getCount() ) {
      my $s;
      $p = $self->{fileLines}->at( $self->{delta}{y} + $i );
      if ( !$p || length( $p ) < $self->{delta}{x} ) {
        $s = EOS;
      }
      else {
        $s = substr( $p, $self->{delta}{x}, $self->{size}{x} );
        if ( length( substr( $p, $self->{delta}{x} ) ) > $self->{size}{x} ) {
          substr( $s, 0, $self->{size}{x} ) = EOS;
        }
      }
      $b->moveStr( 0, substr( $s, 0, maxLineLength ), $c );
    }
    $self->writeBuf( 0, $i, $self->{size}{x}, 1, $b );
  }
  return;
}

sub readFile {    # void ($fName)
  state $sig = signature(
    method => 1,
    pos    => [Str],
  );
  my ( $self, $fName ) = $sig->( @_ );
  $self->{limit}{x}  = 0;
  $self->{fileName}  = $fName;
  $self->{fileLines} = TLineCollection->new( limit => 5, delta => 5 );
  my $fileToView = IO::File->new( $fName, 'r' );
  if ( !defined $fileToView ) {
    messageBox( "Invalid drive or directory", mfError | mfOKButton );
    $self->{isValid} = false;
  }
  else {
    my $line;
    while ( !lowMemory()
      && !$fileToView->eof()
      && defined( $line = $fileToView->getline() )
    ) {
      $line =~ s/\r?\n$//;    # truncate trailing newline
      $self->{limit}{x} = max( $self->{limit}{x}, length( $line ) );
      $self->{fileLines}->insert( $line );
    }
    $self->{isValid} = true;
  }
  $self->{limit}{y} = $self->{fileLines}->getCount();
  return;
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $enable && ( $aState & sfExposed ) ) {
    $self->setLimit( $self->{limit}{x}, $self->{limit}{y} );
  }
  return;
}

sub scrollDraw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->SUPER::scrollDraw();
  $self->draw();
  return;
}

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, undef ) = $sig->( @_ );
  return $self->{isValid}
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::FileViewer - file viewer gadget for text files

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TFileViewer

=head1 SYNOPSIS

  use TUI::Objects::Rect;
  use TUI::Gadgets::FileViewer;
  use TUI::Views::Const qw( :sbXXXX );

  my $r = $self->getExtent();
  $r->grow( -1, -1 );
  $self->insert(
    TFileViewer->new(
      bounds     => $r,
      hScrollBar => $self->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
      vScrollBar => $self->standardScrollBar( sbVertical | sbHandleKeyboard ),
      fileName   => $fileName,
    )
  );

=head1 DESCRIPTION

C<TFileViewer> displays the contents of a text file inside a scrollable view.

The viewer reads the specified file into an internal line collection and
renders the visible portion of the file. Horizontal and vertical scrolling
are provided through the inherited scrolling support from 
L<TScroller|TUI::Views::Scroller>.

=head1 ATTRIBUTES

=head2 fileLines

Collection containing the currently loaded file contents
(I<TLineCollection>).

=head2 fileName

Name of the currently loaded file (I<Str>).

=head2 isValid

Indicates whether the file was loaded successfully (I<Bool>).

=head1 CONSTRUCTOR

=head2 new

  my $viewer = TFileViewer->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar,
    fileName   => $fileName,
  );

Creates a new file viewer and loads the specified file.

=over

=item bounds

Bounding rectangle defining the position and size of the view
(L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Optional horizontal scroll bar (I<TScrollBar>).

=item vScrollBar

Optional vertical scroll bar (I<TScrollBar>).

=item fileName

Name of the file to load (I<Str>).

=back

=head2 new_TFileViewer

  my $viewer = new_TFileViewer(
    $bounds,
    $hScrollBar | undef,
    $vScrollBar | undef,
    $fileName
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $viewer->draw();

Draws the currently visible portion of the file.

=head2 readFile

  $viewer->readFile($fileName);

Loads a text file into the viewer and updates the scrolling limits.

=head2 scrollDraw

  $viewer->scrollDraw();

Refreshes the display after a scrolling operation.

=head2 setState

  $viewer->setState($state, $enable);

Updates the viewer state. When the view becomes exposed, the scrolling
limits are synchronized with the loaded file.

=head2 valid

  my $bool = $viewer->valid($command);

Returns true if the viewer contains valid file data.

=head1 SEE ALSO

L<TScroller|TUI::Views::Scroller>,
L<TLineCollection|TUI::Gadgets::LineCollection>,
L<TFileWindow|TUI::Gadgets::FileWindow>

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
