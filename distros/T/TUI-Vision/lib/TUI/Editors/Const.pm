package TUI::Editors::Const;
# ABSTRACT: constants for editor components

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  maxLineLength
  sfSearchFailed
);

our %EXPORT_TAGS = (

  cmXXXX => [qw(
    cmFind
    cmReplace
    cmSearchAgain
    cmCharLeft
    cmCharRight
    cmWordLeft
    cmWordRight
    cmLineStart
    cmLineEnd
    cmLineUp
    cmLineDown
    cmPageUp
    cmPageDown
    cmTextStart
    cmTextEnd
    cmNewLine
    cmBackSpace
    cmDelChar
    cmDelWord
    cmDelStart
    cmDelEnd
    cmDelLine
    cmInsMode
    cmStartSelect
    cmHideSelect
    cmIndentMode
    cmUpdateTitle
  )],

  cpXXXX => [qw(
    cpEditor
    cpIndicator
    cpMemo
  )],

  edXXXX => [qw(
    edOutOfMemory
    edReadError
    edWriteError
    edCreateError
    edSaveModify
    edSaveUntitled
    edSaveAs
    edFind
    edSearchFailed
    edReplace
    edReplacePrompt
  )],

  efXXXX => [qw(
    efCaseSensitive
    efWholeWordsOnly
    efPromptOnReplace
    efReplaceAll
    efDoReplace
    efBackupFiles
  )],

  smXXXX => [qw(
    smExtend
    smDouble
  )],

  ufXXXX => [qw(
    ufUpdate
    ufLine
    ufView
  )],

);

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

# Palettes
use constant {
  cpEditor    => "\x06\x07",
  cpIndicator => "\x02\x03",
  cpMemo      => "\x1A\x1B",
};

# Update flags
use constant {
  ufUpdate => 0x01,
  ufLine   => 0x02,
  ufView   => 0x04,
};

# Selection modes
use constant {
  smExtend => 0x01,
  smDouble => 0x02,
};

use constant {
  sfSearchFailed => 0xFFFF,
};

# Editor messages
use constant {
  edOutOfMemory   => 0,
  edReadError     => 1,
  edWriteError    => 2,
  edCreateError   => 3,
  edSaveModify    => 4,
  edSaveUntitled  => 5,
  edSaveAs        => 6,
  edFind          => 7,
  edSearchFailed  => 8,
  edReplace       => 9,
  edReplacePrompt => 10,
};

# Commands
use constant {
  cmFind        => 82,
  cmReplace     => 83,
  cmSearchAgain => 84,
};

use constant {
  cmCharLeft    => 500,
  cmCharRight   => 501,
  cmWordLeft    => 502,
  cmWordRight   => 503,
  cmLineStart   => 504,
  cmLineEnd     => 505,
  cmLineUp      => 506,
  cmLineDown    => 507,
  cmPageUp      => 508,
  cmPageDown    => 509,
  cmTextStart   => 510,
  cmTextEnd     => 511,
  cmNewLine     => 512,
  cmBackSpace   => 513,
  cmDelChar     => 514,
  cmDelWord     => 515,
  cmDelStart    => 516,
  cmDelEnd      => 517,
  cmDelLine     => 518,
  cmInsMode     => 519,
  cmStartSelect => 520,
  cmHideSelect  => 521,
  cmIndentMode  => 522,
  cmUpdateTitle => 523,
};

# Search and replace options
use constant {
  efCaseSensitive   => 0x0001,
  efWholeWordsOnly  => 0x0002,
  efPromptOnReplace => 0x0004,
  efReplaceAll      => 0x0008,
  efDoReplace       => 0x0010,
  efBackupFiles     => 0x0100,
};

use constant {
  maxLineLength => 256,
};

1

__END__

=pod

=head1 NAME

TUI::Editors::Const - constants for editor components

=head1 SYNOPSIS

  use TUI::Editors;

  my $flags = efReplaceAll | efPromptOnReplace;

=head1 DESCRIPTION

This module defines constants used by L<TUI::Vision> editor components.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding editor modules.

=head1 CONSTANTS

=head2 Editor color palettes (cpXXXX)

Color palette constants used by editor components.

These values define the color schemes for editor elements, such as the
position indicator L<TIndicator|TUI::Editors::Indicator>.

=head2 Editor messages (edXXXX)

Message identifiers used by the editor components to report state to the
application, such as a failed search (C<edSearchFailed>) or a request to save
modified text (C<edSaveModify>).

=head2 Editor command constants (cmXXXX)

Command identifiers used by the editor components.

These values are delivered via C<< $event->{message}{command} >> and are handled
by L<TEditor|TUI::Editors::Editor>, including the search and replace commands
(C<cmFind>, C<cmReplace>, C<cmSearchAgain>).

=head2 Editor update flags (ufXXXX)

Flags that tell L<TEditor|TUI::Editors::Editor> which parts of the view must be
redrawn when it is updated: the whole view (C<ufView>), a single line
(C<ufLine>), or the update state itself (C<ufUpdate>).

=head2 Editor selection modes (smXXXX)

Flags that describe how the cursor movement of L<TEditor|TUI::Editors::Editor>
extends the current selection: extending it (C<smExtend>) and selecting by word
(C<smDouble>).

=head2 Editor search and replace options (efXXXX)

Option flags for the search and replace dialog of the editor, used by
L<TEditor|TUI::Editors::Editor> C<find>, C<replace> and C<search>.

=head2 Editor line length (maxLineLength)

C<maxLineLength> is the maximum length of a line in an editor, used as the
horizontal scroll limit of L<TEditor|TUI::Editors::Editor>. It is exported by
C<:all> and can also be imported by name.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item * C<:cpXXXX> - editor color palettes

=item * C<:edXXXX> - editor messages

=item * C<:cmXXXX> - editor command identifiers

=item * C<:ufXXXX> - editor update flags

=item * C<:smXXXX> - editor selection modes

=item * C<:efXXXX> - editor search and replace options

=item * C<:all> - import all constants, including C<maxLineLength>

=back

=head1 SEE ALSO

L<TUI::Editors>

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
