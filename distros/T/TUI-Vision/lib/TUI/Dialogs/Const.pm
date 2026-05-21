package TUI::Dialogs::Const;
# ABSTRACT: constants for dialog components

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  bfXXXX => [qw(
    bfNormal
    bfDefault
    bfLeftJust
    bfBroadcast
    bfGrabFocus
  )],

  cmXXXX => [qw(
    cmRecordHistory
    cmGrabDefault
    cmReleaseDefault
  )],

  cpXXXX => [qw(
    cpGrayDialog
    cpBlueDialog
    cpCyanDialog
    cpButton
    cpCluster
    cpDialog
    cpInputLine
    cpLabel
    cpStaticText
    cpHistoryViewer
    cpHistoryWindow
    cpHistory
  )],
  
  dpXXXX => [qw(
    dpBlueDialog
    dpCyanDialog
    dpGrayDialog
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

# Button flags

use constant {
  bfNormal    => 0x00,
  bfDefault   => 0x01,
  bfLeftJust  => 0x02,
  bfBroadcast => 0x04,
  bfGrabFocus => 0x08,
};

# Command constants

use constant {
  # History Command constants
  cmRecordHistory => 60,

  # TButton Command constants
  cmGrabDefault    => 61,
  cmReleaseDefault => 62,
};

# TDialog palette layout

use constant cpGrayDialog =>
  "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F".
  "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3A\x3B\x3C\x3D\x3E\x3F";

use constant cpBlueDialog =>
  "\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f".
  "\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f";

use constant cpCyanDialog =>
  "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f".
  "\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f";

use constant cpDialog => cpGrayDialog;

# TButton palette layout

use constant cpButton => "\x0A\x0B\x0C\x0D\x0E\x0E\x0E\x0F";

# TStaticText palette layout

use constant cpStaticText => "\x06";

# TInputLine palette layout

use constant cpInputLine => "\x13\x13\x14\x15";

# TLabel palette layout

use constant cpLabel => "\x07\x08\x09\x09";

# TCluster palette layout

use constant cpCluster => "\x10\x11\x12\x12\x1f";

# THistoryViewer palette layout

use constant cpHistoryViewer => "\x06\x06\x07\x06\x06";

# THistoryWindow palette layout

use constant cpHistoryWindow => "\x13\x13\x15\x18\x17\x13\x14";

# THistory palette layout

use constant cpHistory => "\x16\x17";

# TDialog palette entries

use constant {
  dpBlueDialog => 0,
  dpCyanDialog => 1,
  dpGrayDialog => 2,
};

1

__END__

=pod

=head1 NAME

TUI::Dialogs::Const - constants for dialog components

=head1 SYNOPSIS

  use TUI::Dialogs::Const qw(:all);

  # or import specific constant groups
  use TUI::Dialogs::Const qw(:bfXXXX :cmXXXX :cpXXXX);

=head1 DESCRIPTION

C<TUI::Dialogs::Const> defines constants used by TUI::Vision dialog components
such as dialogs, buttons, labels, input lines, and history views.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They control dialog behavior, button flags, command handling,
palette layouts, and dialog palette selection.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in higher-level modules such as C<TUI::Dialogs>,
C<TDialog>, and the individual dialog view classes.

=head1 CONSTANTS

=head2 Button flags (bfXXXX)

Flags controlling the behavior and appearance of dialog buttons.

These flags are used when creating button views and may be combined to modify
default handling, focus behavior, and event broadcasting.

=head2 Dialog command constants (cmXXXX)

Command identifiers used by dialog-related components.

These values are delivered via C<$event-E<gt>{command}> and are handled by
dialogs, buttons, and history components.

=head2 Dialog palette layouts (cpXXXX)

Palette layouts used by dialog views and dialog-related components.

These constants define the color layout for dialogs, buttons, labels, input
lines, clusters, and history views.

=head2 Dialog palette selectors (dpXXXX)

Constants used to select the active dialog palette variant.

These values identify the blue, cyan, and gray dialog palette configurations.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:bfXXXX> - button flags

=item *

C<:cmXXXX> - dialog command identifiers

=item *

C<:cpXXXX> - dialog palette layouts

=item *

C<:dpXXXX> - dialog palette selectors

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::Dialogs>,
L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Button>,
L<TUI::Dialogs::InputLine>,
L<TUI::Dialogs::History>

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
