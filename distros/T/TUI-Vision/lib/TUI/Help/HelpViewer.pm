package TUI::Help::HelpViewer;
# ABSTRACT: scrollable help topic viewer

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THelpViewer
  new_THelpViewer
);

use Carp ();
use File::Spec ();
use IO::File;
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Const qw(
  evCommand
  evKeyDown
  evMouseDown
  kbEnter
  kbEsc
  kbShiftTab
  kbTab
  meDoubleClick
);
use TUI::Help::Const qw( cHelpViewer );
use TUI::Help::HelpFile;
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  cmClose
  gfGrowHiX
  gfGrowHiY
  sfModal
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::Scroller;

sub THelpViewer() { __PACKAGE__ }
sub name() { 'THelpViewer' }
sub new_THelpViewer { __PACKAGE__->from(@_) }

extends TScroller;

# public attributes
has hFile    => ( is => 'rw', default => sub { die 'required' } );
has topic    => ( is => 'rw' );
has selected => ( is => 'rw', default => 1 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
      hFile      => Object,        { alias => 'aHelpFile'   },
      context    => PositiveOrZeroInt,
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
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  $self->{topic} = $self->{hFile}->getTopic( $args->{context} );
  $self->{topic}->setWidth( $self->{size}{x} );
  $self->setLimit( 78, $self->{topic}->numLines() );
  return;
}

sub from {    # $viewer ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, $aHelpFile, $context)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object], Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2], hFile => $args[3], context => $args[4] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  undef $self->{topic};
  undef $self->{hFile};
  return;
}

sub changeBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->SUPER::changeBounds( $bounds );
  $self->{topic}->setWidth( $self->{size}{x} );
  $self->setLimit( $self->{limit}{x}, $self->{topic}->numLines() );
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $topic = $self->{topic};
  my $normal     = $self->getColor( 1 );
  my $keyword    = $self->getColor( 2 );
  my $selKeyword = $self->getColor( 3 );
  my $keyCount  = 0;
  my $keyPoint  = TPoint->new();
  my $keyLength = 0;
  my $keyRef    = 0;

  $topic->setWidth( $self->{size}{x} );
  if ( $topic->getNumCrossRefs() > 0 ) {
    do {
      $topic->getCrossRef( $keyCount, $keyPoint, \$keyLength, \$keyRef );
      ++$keyCount;
    } while ( $keyCount < $topic->getNumCrossRefs()
      && $keyPoint->{y} <= $self->{delta}{y} );
  }

  for my $i ( 1 .. $self->{size}{y} ) {
    my $b = TDrawBuffer->new();
    $b->moveChar( 0, ' ', $normal, $self->{size}{x} );
    my $buffer = '';
    my $line = $topic->getLine( $i + $self->{delta}{y}, \$buffer, 256 );
    if ( length( $line ) > $self->{delta}{x} ) {
      $b->moveStr( 0,
        substr( $line, $self->{delta}{x}, $self->{size}{x} ), $normal );
    }
    else {
      $b->moveStr( 0, '', $normal );
    }

    while ( $i + $self->{delta}{y} == $keyPoint->{y} ) {
      my $l = $keyLength;
      if ( $keyPoint->{x} < $self->{delta}{x} ) {
        $l -= $self->{delta}{x} - $keyPoint->{x};
        $keyPoint->{x} = $self->{delta}{x};
      }
      my $c = $keyCount == $self->{selected} ? $selKeyword : $keyword;
      for my $j ( 0 .. $l - 1 ) {
        $b->putAttribute( $keyPoint->{x} - $self->{delta}{x} + $j, $c );
      }
      if ( $keyCount < $topic->getNumCrossRefs() ) {
        $topic->getCrossRef( $keyCount, $keyPoint, \$keyLength, \$keyRef );
        $keyCount++;
      }
      else {
        $keyPoint->{y} = 0;
      }
    }
    $self->writeLine( 0, $i - 1, $self->{size}{x}, 1, $b );
  }
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cHelpViewer,
    size => length( cHelpViewer ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  my $keyPoint  = TPoint->new();
  my $keyLength = 0;
  my $keyRef    = 0;

  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    evKeyDown == $_ and do {
      SWITCH: for ( $event->{keyDown}{keyCode} ) {
        kbTab == $_ and do {
          ++$self->{selected};
          if ( $self->{selected} > $self->{topic}->getNumCrossRefs() ) {
            $self->{selected} = 1;
          }
          if ( $self->{topic}->getNumCrossRefs() != 0 ) {
            $self->makeSelectVisible( $self->{selected} - 1, $keyPoint,
              \$keyLength, \$keyRef );
          }
          last;
        };
        kbShiftTab == $_ and do {
          --$self->{selected};
          if ( $self->{selected} == 0 ) {
            $self->{selected} = $self->{topic}->getNumCrossRefs();
          }
          if ( $self->{topic}->getNumCrossRefs() != 0 ) {
            $self->makeSelectVisible( $self->{selected} - 1, $keyPoint,
              \$keyLength, \$keyRef );
          }
          last;
        };
        kbEnter == $_ and do {
          if ( $self->{selected} <= $self->{topic}->getNumCrossRefs() ) {
            $self->{topic}->getCrossRef( $self->{selected} - 1, $keyPoint,
              \$keyLength, \$keyRef );
            $self->switchToTopic( $keyRef );
          }
          last;
        };
        kbEsc == $_ and do {
          $event->{what}             = evCommand;
          $event->{message}{command} = cmClose;
          $self->putEvent( $event );
          last;
        };
        DEFAULT: {
          return;
        }
      } #/ SWITCH: for ( $event->{keyDown}{keyCode} )
      $self->drawView();
      $self->clearEvent( $event );
      last;
    };

    evMouseDown == $_ and do {
      my $mouse = $self->makeLocal( $event->{mouse}{where} );
      $mouse->{x} += $self->{delta}{x};
      $mouse->{y} += $self->{delta}{y};
      my $keyCount = 0;
      do {
        ++$keyCount;
        return
          if $keyCount > $self->{topic}->getNumCrossRefs();
        $self->{topic}->getCrossRef( $keyCount - 1, $keyPoint,
          \$keyLength, \$keyRef );
      } while ( !( $keyPoint->{y} == $mouse->{y} + 1
        && $mouse->{x} >= $keyPoint->{x}
        && $mouse->{x} < $keyPoint->{x} + $keyLength ) );
      $self->{selected} = $keyCount;
      $self->drawView();
      if ( $event->{mouse}{eventFlags} & meDoubleClick ) {
        $self->switchToTopic( $keyRef );
      }
      $self->clearEvent( $event );
      last;
    };

    evCommand == $_ and do {
      if ( $event->{message}{command} == cmClose
        && $self->{owner}
        && ( $self->{owner}{state} & sfModal ) != 0
      ) {
        $self->endModal( cmClose );
        $self->clearEvent( $event );
      }
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
}

sub makeSelectVisible {    # void ($selected, $keyPoint, \$keyLength, \$keyRef)
  state $sig = signature(
    method => Object,
    pos    => [
      Int,
      Object,
      ScalarRef[PositiveOrZeroInt],
      ScalarRef[Int],
    ],
  );
  my ( $self, $selected, $keyPoint, $keyLength, $keyRef ) = $sig->( @_ );
  $self->{topic}->getCrossRef( $selected, $keyPoint, $keyLength, $keyRef );
  my $d = TPoint->new();
  $d->{x} = $self->{delta}{x};
  $d->{y} = $self->{delta}{y};
  if ( $keyPoint->{x} < $d->{x} ) {
    $d->{x} = $keyPoint->{x};
  }
  if ( $keyPoint->{x} > $d->{x} + $self->{size}{x} ) {
    $d->{x} = $keyPoint->{x} - $self->{size}{x};
  }
  if ( $keyPoint->{y} <= $d->{y} ) {
    $d->{y} = $keyPoint->{y} - 1;
  }
  if ( $keyPoint->{y} > $d->{y} + $self->{size}{y} ) {
    $d->{y} = $keyPoint->{y} - $self->{size}{y};
  }
  if ( $d->{x} != $self->{delta}{x} || $d->{y} != $self->{delta}{y} ) {
    $self->scrollTo( $d->{x}, $d->{y} );
  }
  return;
}

sub switchToTopic {    # void ($keyRef)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $keyRef ) = $sig->( @_ );
  $self->{topic} = $self->{hFile}->getTopic( $keyRef );
  $self->{topic}->setWidth( $self->{size}{x} );
  $self->scrollTo( 0, 0 );
  $self->setLimit( $self->{limit}{x}, $self->{topic}->numLines() );
  $self->{selected} = 1;
  $self->drawView();
  return;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  open my $devnull, '<', File::Spec->devnull
    or Carp::croak( "Cannot open devnull: $!" );
  return $class->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
    hFile      => THelpFile->new( stream => $devnull ),
    context    => 0,
  );
}

1

__END__

=pod

=head1 NAME

TUI::Help::HelpViewer - scrollable help topic viewer

=head1 HIERARCHY

  TObject
    TView
      TScroller
        THelpViewer

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Help;

  open my $source, '<', 'help.txt' or die $!;
  my $helpFile = new_THelpFile( $source );

  my $viewer = new_THelpViewer(
    TRect->new( ax => 0, ay => 0, bx => 60, by => 18 ),
    undef,        # no horizontal scroll bar
    undef,        # no vertical scroll bar
    $helpFile,
    10,           # help context of the first topic
  );

=head1 DESCRIPTION

C<THelpViewer> displays one help topic in a scrollable view. It is the Perl
port of the Turbo Vision C<THelpViewer> and derives from L<TScroller|
TUI::Views::Scroller>. The viewer is selectable and grows with its owner in
both directions. It keeps the help file in C<hFile> and the current topic in
C<topic>. The topic is read from the help file by its numeric context when
the viewer is constructed. The topic is wrapped to the width of the viewer,
the horizontal scroll limit is 78 columns, and the vertical limit is the
number of lines in the topic. If the context is unknown, the viewer shows the
invalid-context text provided by L<THelpFile|TUI::Help::HelpFile>.

Cross-references in the topic are highlighted. At most one cross-reference is
selected at a time; C<selected> holds its one-based index and starts at 1.
The selected reference is drawn with the selected-keyword color, and the
other references use the keyword color.

=head2 Commonly Used Features

Create the help file from an open, seekable handle with C<new_THelpFile>, then
create the viewer with bounds, the two scroll bar arguments (which may be
C<undef>), the help file, and the numeric context of the first topic. Insert
the viewer into a window and run that window modally with C<execView>.
Keyboard users move between cross-references with Tab and Shift-Tab and
follow one with Enter. Mouse users click a cross-reference to select it and
double-click it to follow it. Esc posts a C<cmClose> command. The viewer ends
the modal view only when its owner is modal; otherwise it leaves the command
unhandled.

=head1 ATTRIBUTES

The following attributes are read/write:

=over

=item hFile

The L<THelpFile|TUI::Help::HelpFile> object that supplies the topics. It is
required by the constructor. The help file keeps its source handle, which
remains owned by the caller.

=item topic

The current L<THelpTopic|TUI::Help::HelpTopic>. It is set by the constructor
and replaced when a cross-reference is followed.

=item selected

The one-based index of the selected cross-reference (C<Int>). It starts at 1
and is reset to 1 when another topic is shown.

=back

=head1 CONSTRUCTOR

=head2 new

  my $viewer = THelpViewer->new(
    bounds     => $bounds,
    hScrollBar => $hBar | undef,
    vScrollBar => $vBar | undef,
    hFile      => $helpFile,
    context    => $context,
  );

Creates a viewer for the topic with the numeric context C<$context>. All five
arguments are required. The scroll bar arguments must be present as keys, but
either may be C<undef>. The arguments C<aHScrollBar>, C<aVScrollBar>, and
C<aHelpFile> are accepted as aliases for C<hScrollBar>, C<vScrollBar>, and
C<hFile>.

=over

=item bounds

Bounding rectangle of the viewer (L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar>) or C<undef>.

=item vScrollBar

Vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar>) or C<undef>.

=item hFile

Help file (L<THelpFile|TUI::Help::HelpFile>) that supplies the topics.

=item context

Numeric help context (C<PositiveOrZeroInt>) of the first topic to display.

=back

=head2 new_THelpViewer

  my $viewer = new_THelpViewer( $bounds, $hBar | undef, $vBar | undef,
    $helpFile, $context );

Positional factory for the same constructor, with the arguments in the order
listed above.

=head1 METHODS

The following methods override the corresponding methods of
L<TScroller|TUI::Views::Scroller>.

=head2 changeBounds

  $viewer->changeBounds($bounds);

Applies the new bounds through the scroller and rewraps the current topic to
the new width. The vertical scroll limit is updated to the number of lines in
the rewrapped topic. The horizontal limit is unchanged.

=head2 draw

  $viewer->draw();

Draws the visible part of the topic at the current scroll offset. Normal text
uses palette entry 1, cross-references use palette entry 2, and the selected
cross-reference uses palette entry 3.

=head2 getPalette

  my $palette = $viewer->getPalette();

Returns a copy of the palette of the help viewer, which is built from the
constant C<cHelpViewer>.

=head2 handleEvent

  $viewer->handleEvent($event);

Passes the event to the scroller first, then handles the following events:

=over

=item * Tab selects the next cross-reference and wraps from the last one to
the first. Shift-Tab selects the previous one and wraps from the first one to
the last.

=item * Enter follows the selected cross-reference, which replaces C<topic>,
resets C<selected> to 1, and scrolls the view to the top.

=item * A mouse click on a cross-reference selects it. A double-click
(C<meDoubleClick>) also follows it.

=item * Esc is consumed and posts a C<cmClose> command.

=item * A C<cmClose> command ends the modal view with C<cmClose> when the owner
has C<sfModal> set. The command is consumed in that case. Otherwise it is left
unhandled.

=back

Other keys and events are not consumed.

=head1 SEE ALSO

L<TUI::Help>, L<THelpFile|TUI::Help::HelpFile>, L<THelpTopic|TUI::Help::HelpTopic>,
L<TUI::Help::Const>, L<TScroller|TUI::Views::Scroller>

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
