package TUI::Views::Const;
# ABSTRACT: defines various constants used throughout views and windows

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  maxViewWidth
);

our %EXPORT_TAGS = (

  phaseType => [qw(
    phFocused
    phPreProcess
    phPostProcess
  )],

  selectMode => [qw(
    normalSelect
    enterSelect
    leaveSelect
  )],

  cmXXXX => [qw(
    cmValid
    cmQuit
    cmError
    cmMenu
    cmClose
    cmZoom
    cmResize
    cmNext
    cmPrev
    cmHelp

    cmOK
    cmCancel
    cmYes
    cmNo
    cmDefault

    cmNew
    cmOpen
    cmSave
    cmSaveAs
    cmSaveAll
    cmChDir
    cmDosShell
    cmCloseAll
    
    cmCut
    cmCopy
    cmPaste
    cmUndo
    cmClear
    cmTile
    cmCascade

    cmReceivedFocus
    cmReleasedFocus
    cmCommandSetChanged
    cmScrollBarChanged
    cmScrollBarClicked
    cmSelectWindowNum
    cmListItemSelected
  )],

  sfXXXX => [qw(
    sfVisible
    sfCursorVis
    sfCursorIns
    sfShadow
    sfActive
    sfSelected
    sfFocused
    sfDragging
    sfDisabled
    sfModal
    sfDefault
    sfExposed
  )],

  ofXXXX => [qw(
    ofSelectable
    ofTopSelect
    ofFirstClick
    ofFramed
    ofPreProcess
    ofPostProcess
    ofBuffered
    ofTileable
    ofCenterX
    ofCenterY
    ofCentered
    ofValidate
  )],

  gfXXXX => [qw(
    gfGrowLoX
    gfGrowLoY
    gfGrowHiX
    gfGrowHiY
    gfGrowAll
    gfGrowRel
    gfFixed
  )],

  dmXXXX => [qw(
    dmDragMove
    dmDragGrow
    dmLimitLoX
    dmLimitLoY
    dmLimitHiX
    dmLimitHiY
    dmLimitAll
  )],

  hcXXXX => [qw(
    hcNoContext
    hcDragging
  )],

  sbXXXX => [qw(
    sbLeftArrow
    sbRightArrow
    sbPageLeft
    sbPageRight
    sbUpArrow
    sbDownArrow
    sbPageUp
    sbPageDown
    sbIndicator
    sbHorizontal
    sbVertical
    sbHandleKeyboard
  )],

  wfXXXX => [qw(
    wfMove
    wfGrow
    wfClose
    wfZoom
  )],

  noXXXX => [qw(
    noMenuBar
    noDeskTop
    noStatusLine
    noBackground
    noFrame
    noViewer
    noHistory
  )],

  wnXXXX => [qw(
    wnNoNumber
  )],

  wpXXXX => [qw(
    wpBlueWindow
    wpCyanWindow
    wpGrayWindow
  )],

  evXXXX => [qw(
    positionalEvents
    focusedEvents
  )],

  cpXXXX => [qw(
    cpFrame
    cpScroller
    cpScrollBar
    cpBlueWindow
    cpCyanWindow
    cpGrayWindow
    cpListViewer
  )],

);

use TUI::Drivers::Const qw(
  evMouse
  evKeyboard
  evCommand
);

use constant {
  maxViewWidth    => 132,
};

# Constants for phaseType
use constant {
  phFocused       => 0,
  phPreProcess    => 1,
  phPostProcess   => 2,
};

# Constants for selectMode
use constant {
  normalSelect    => 0,
  enterSelect     => 1,
  leaveSelect     => 2,
};

use constant {
  # Standard command codes
  cmValid         => 0,
  cmQuit          => 1,
  cmError         => 2,
  cmMenu          => 3,
  cmClose         => 4,
  cmZoom          => 5,
  cmResize        => 6,
  cmNext          => 7,
  cmPrev          => 8,
  cmHelp          => 9,
};

use constant {
  # TDialog standard commands
  cmOK            => 10,
  cmCancel        => 11,
  cmYes           => 12,
  cmNo            => 13,
  cmDefault       => 14,
};

use constant {
  # Standard application commands
  cmNew           => 30,
  cmOpen          => 31,
  cmSave          => 32,
  cmSaveAs        => 33,
  cmSaveAll       => 34,
  cmChDir         => 35,
  cmDosShell      => 36,
  cmCloseAll      => 37,
};

use constant {
  # TView State masks
  sfVisible       => 0x001,
  sfCursorVis     => 0x002,
  sfCursorIns     => 0x004,
  sfShadow        => 0x008,
  sfActive        => 0x010,
  sfSelected      => 0x020,
  sfFocused       => 0x040,
  sfDragging      => 0x080,
  sfDisabled      => 0x100,
  sfModal         => 0x200,
  sfDefault       => 0x400,
  sfExposed       => 0x800,
};

use constant {
  # TView Option masks
  ofSelectable    => 0x001,
  ofTopSelect     => 0x002,
  ofFirstClick    => 0x004,
  ofFramed        => 0x008,
  ofPreProcess    => 0x010,
  ofPostProcess   => 0x020,
  ofBuffered      => 0x040,
  ofTileable      => 0x080,
  ofCenterX       => 0x100,
  ofCenterY       => 0x200,
  ofCentered      => 0x300,
  ofValidate      => 0x400,
};

use constant {
  # TView GrowMode masks
  gfGrowLoX       => 0x01,
  gfGrowLoY       => 0x02,
  gfGrowHiX       => 0x04,
  gfGrowHiY       => 0x08,
  gfGrowAll       => 0x0f,
  gfGrowRel       => 0x10,
  gfFixed         => 0x20,
};

use constant {
  # TView DragMode masks
  dmDragMove      => 0x01,
  dmDragGrow      => 0x02,
  dmLimitLoX      => 0x10,
  dmLimitLoY      => 0x20,
  dmLimitHiX      => 0x40,
  dmLimitHiY      => 0x80,
  dmLimitAll      => 0xF0,
};

use constant {
  # TView Help context codes
  hcNoContext     => 0,
  hcDragging      => 1,
};

use constant {
  # TScrollBar part codes
  sbLeftArrow     => 0,
  sbRightArrow    => 1,
  sbPageLeft      => 2,
  sbPageRight     => 3,
  sbUpArrow       => 4,
  sbDownArrow     => 5,
  sbPageUp        => 6,
  sbPageDown      => 7,
  sbIndicator     => 8,
};

use constant {
  # TScrollBar options for TWindow->standardScrollBar
  sbHorizontal      => 0x000,
  sbVertical        => 0x001,
  sbHandleKeyboard  => 0x002,
};

use constant {
  # TWindow Flags masks
  wfMove          => 0x01,
  wfGrow          => 0x02,
  wfClose         => 0x04,
  wfZoom          => 0x08,
};

use constant {
  # TView inhibit flags
  noMenuBar       => 0x0001,
  noDeskTop       => 0x0002,
  noStatusLine    => 0x0004,
  noBackground    => 0x0008,
  noFrame         => 0x0010,
  noViewer        => 0x0020,
  noHistory       => 0x0040,
};

use constant {
  # TWindow number constants
  wnNoNumber      => 0,
};

use constant {
  # TWindow palette entries
  wpBlueWindow    => 0,
  wpCyanWindow    => 1,
  wpGrayWindow    => 2,
};

use constant {
  # Application command codes
  cmCut           => 20,
  cmCopy          => 21,
  cmPaste         => 22,
  cmUndo          => 23,
  cmClear         => 24,
  cmTile          => 25,
  cmCascade       => 26,
};

use constant {
  # Standard messages
  cmReceivedFocus     => 50,
  cmReleasedFocus     => 51,
  cmCommandSetChanged => 52,
};

use constant {
  # TScrollBar messages
  cmScrollBarChanged  => 53,
  cmScrollBarClicked  => 54,
};

use constant {
  # TWindow select messages
  cmSelectWindowNum   => 55,
};

use constant {
  # TListViewer messages
  cmListItemSelected  => 56,
};

use constant {
  # Event masks
  positionalEvents    => evMouse,
  focusedEvents       => evKeyboard | evCommand,
};

use constant {
  # TFrame palette
  cpFrame => "\x01\x01\x02\x02\x03",
};

use constant {
  # cpScroller palette
  cpScroller => "\x06\x07",
};

use constant {
  # TScrollBar palette
  cpScrollBar => "\x04\x05\x05",
};

use constant {
  # TWindow palettes
  cpBlueWindow => "\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F",
  cpCyanWindow => "\x10\x11\x12\x13\x14\x15\x16\x17",
  cpGrayWindow => "\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F",
};

use constant {
  # TListViewer palette
  cpListViewer => "\x1A\x1A\x1B\x1C\x1D",
};

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

1

__END__

=pod

=head1 NAME

TUI::Views::Const - constants for view and window components

=head1 SYNOPSIS

  use TUI::Views::Const qw(:all);

  # or import specific constant groups
  use TUI::Views::Const qw(:cmXXXX :sfXXXX :ofXXXX);

=head1 DESCRIPTION

C<TUI::Views::Const> defines constants used by TUI::Vision view, window, and
scrollbar components.

The constants in this module follow the naming conventions of Turbo Vision 2.0
and are provided using lower camel case identifiers. They are grouped by
purpose and exported via tag-based export groups.

These constants control view state, option flags, grow and drag modes, command
handling, palette selection, and event filtering.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in higher-level modules such as C<TUI::Views>,
C<TView>, C<TWindow>, and the individual view classes.

=head1 CONSTANTS

=head2 Phase and selection constants

Constants used during view event processing and selection handling.

=head2 Command constants (cmXXXX)

Command identifiers used by views, dialogs, windows, and application-level
components.

These values are delivered via C<$event-E<gt>{command}> and are handled by view
and window classes.

=head2 View state flags (sfXXXX)

State flags describing the current state of a view, such as visibility,
focus, selection, and modality.

=head2 View option flags (ofXXXX)

Option flags controlling how views participate in event handling, layout,
validation, and buffering.

=head2 Grow mode flags (gfXXXX)

Flags controlling how views resize when their owner changes size.

=head2 Drag mode flags (dmXXXX)

Flags controlling how views behave during mouse drag operations.

=head2 Help context constants (hcXXXX)

Help context identifiers used by views during interactive operations.

=head2 Scroll bar constants (sbXXXX)

Constants identifying scroll bar parts, directions, and behavior options.

=head2 Window flags (wfXXXX)

Flags controlling window capabilities such as moving, resizing, closing, and
zooming.

=head2 Inhibit flags (noXXXX)

Flags used to disable specific view or window components.

=head2 Window numbering and palette constants

Constants used for window numbering, palette selection, and color layout of
views and windows.

=head2 Event mask constants (evXXXX)

Event mask constants used to filter positional and focused events.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:phaseType>, C<:selectMode>

=item *

C<:cmXXXX>, C<:hcXXXX>

=item *

C<:sfXXXX>, C<:ofXXXX>

=item *

C<:gfXXXX>, C<:dmXXXX>

=item *

C<:sbXXXX>, C<:wfXXXX>, C<:noXXXX>

=item *

C<:wpXXXX>, C<:cpXXXX>

=item *

C<:evXXXX>

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::Views>,
L<TUI::Views::View>,
L<TUI::Views::Window>,
L<TUI::Views::ScrollBar>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
