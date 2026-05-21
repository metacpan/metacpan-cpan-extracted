package TUI::App::Const;
# ABSTRACT: constants for TUI::App and related components

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  cpXXXX => [qw(
    cpBackground
    cpAppColor
    cpAppBlackWhite
    cpAppMonochrome
  )],
  
  hcXXXX => [qw(
    hcNew
    hcOpen
    hcSave
    hcSaveAs
    hcSaveAll
    hcChangeDir
    hcDosShell
    hcExit

    hcUndo
    hcCut
    hcCopy
    hcPaste
    hcClear

    hcTile
    hcCascade
    hcCloseAll
    hcResize
    hcZoom
    hcNext
    hcPrev
    hcClose
  )],

  apXXXX => [qw(
    apColor
    apBlackWhite
    apMonochrome
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

# Turbo Vision 2.0 Color Palettes

use constant cpBackground =>  "\x01";    # background palette

use constant cpAppColor =>
      "\x71\x70\x78\x74\x20\x28\x24\x17\x1F\x1A\x31\x31\x1E\x71\x1F".
  "\x37\x3F\x3A\x13\x13\x3E\x21\x3F\x70\x7F\x7A\x13\x13\x70\x7F\x7E".
  "\x70\x7F\x7A\x13\x13\x70\x70\x7F\x7E\x20\x2B\x2F\x78\x2E\x70\x30".
  "\x3F\x3E\x1F\x2F\x1A\x20\x72\x31\x31\x30\x2F\x3E\x31\x13\x38\x00".
  "\x17\x1F\x1A\x71\x71\x1E\x17\x1F\x1E\x20\x2B\x2F\x78\x2E\x10\x30".
  "\x3F\x3E\x70\x2F\x7A\x20\x12\x31\x31\x30\x2F\x3E\x31\x13\x38\x00".
  "\x37\x3F\x3A\x13\x13\x3E\x30\x3F\x3E\x20\x2B\x2F\x78\x2E\x30\x70".
  "\x7F\x7E\x1F\x2F\x1A\x20\x32\x31\x71\x70\x2F\x7E\x71\x13\x78\x00".
  "\x37\x3F\x3A\x13\x13\x30\x3E\x1E";    # help colors

use constant cpAppBlackWhite =>
      "\x70\x70\x78\x7F\x07\x07\x0F\x07\x0F\x07\x70\x70\x07\x70\x0F".
  "\x07\x0F\x07\x70\x70\x07\x70\x0F\x70\x7F\x7F\x70\x07\x70\x07\x0F".
  "\x70\x7F\x7F\x70\x07\x70\x70\x7F\x7F\x07\x0F\x0F\x78\x0F\x78\x07".
  "\x0F\x0F\x0F\x70\x0F\x07\x70\x70\x70\x07\x70\x0F\x07\x07\x08\x00".
  "\x07\x0F\x0F\x07\x70\x07\x07\x0F\x0F\x70\x78\x7F\x08\x7F\x08\x70".
  "\x7F\x7F\x7F\x0F\x70\x70\x07\x70\x70\x70\x07\x7F\x70\x07\x78\x00".
  "\x70\x7F\x7F\x70\x07\x70\x70\x7F\x7F\x07\x0F\x0F\x78\x0F\x78\x07".
  "\x0F\x0F\x0F\x70\x0F\x07\x70\x70\x70\x07\x70\x0F\x07\x07\x08\x00".
  "\x07\x0F\x07\x70\x70\x07\x0F\x70";    # help colors

use constant cpAppMonochrome =>
      "\x70\x07\x07\x0F\x70\x70\x70\x07\x0F\x07\x70\x70\x07\x70\x00".
  "\x07\x0F\x07\x70\x70\x07\x70\x00\x70\x70\x70\x07\x07\x70\x07\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x70\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x01\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x01\x00".
  "\x07\x0F\x07\x70\x70\x07\x0F\x70";    # help colors

# Standard application help contexts

# Note: range 0xFF00 - 0xFFFF of help contexts are reserved by Borland
use constant {
  hcNew          => 0xFF01,
  hcOpen         => 0xFF02,
  hcSave         => 0xFF03,
  hcSaveAs       => 0xFF04,
  hcSaveAll      => 0xFF05,
  hcChangeDir    => 0xFF06,
  hcDosShell     => 0xFF07,
  hcExit         => 0xFF08,
};

use constant {
  hcUndo         => 0xFF10,
  hcCut          => 0xFF11,
  hcCopy         => 0xFF12,
  hcPaste        => 0xFF13,
  hcClear        => 0xFF14,
};

use constant {
  hcTile         => 0xFF20,
  hcCascade      => 0xFF21,
  hcCloseAll     => 0xFF22,
  hcResize       => 0xFF23,
  hcZoom         => 0xFF24,
  hcNext         => 0xFF25,
  hcPrev         => 0xFF26,
  hcClose        => 0xFF27,
};

# TApplication palette entries

use constant {
  apColor      => 0,
  apBlackWhite => 1,
  apMonochrome => 2,
};

1

__END__

=pod

=head1 NAME

TUI::App::Const - constants for application-level components

=head1 SYNOPSIS

  use TUI::App::Const qw(:all);

  # or import specific constant groups
  use TUI::App::Const qw(:cpXXXX :hcXXXX);

=head1 DESCRIPTION

C<TUI::App::Const> defines constants used by TUI::Vision application-level
components such as the program object, application palettes, and help system.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used to control application appearance, help context
selection, and palette configuration.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in higher-level modules such as C<TUI::App>,
C<TProgram>, and C<TApplication>.

=head1 CONSTANTS

=head2 Palette constants (cpXXXX)

Palette identifiers and palette data used by application-level views.

These constants define background palettes and the standard application color
schemes used by the program and application objects.

=head2 Help context constants (hcXXXX)

Help context identifiers used by application menus, dialogs, and commands.

These values are passed to the help system to identify the appropriate help
topic for a given command or user action.

=head2 Application palette selectors (apXXXX)

Constants used to select the active application palette.

These values identify the color, black-and-white, and monochrome application
palette variants.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:cpXXXX> - application palette constants

=item *

C<:hcXXXX> - help context identifiers

=item *

C<:apXXXX> - application palette selectors

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::App>,
L<TUI::App::Program>,
L<TUI::App::Application>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
