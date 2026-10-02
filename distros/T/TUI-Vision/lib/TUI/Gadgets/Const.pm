package TUI::Gadgets::Const;
# ABSTRACT: constants for gadget components

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  maxLineLength
);

our %EXPORT_TAGS = (

  cmXXXX => [qw(
    cmFndEventView
  )],

  cpXXXX => [qw(
    cpMousePalette
  )],

  hlXXXX => [qw(
    hlChangeDir
  )],

);

use TUI::StdDlg::Const qw( cmChangeDir );

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

# Constants for Gadgets events
use constant {
  cmFndEventView => 114,
};

# History id for the change directory dialog
use constant {
  hlChangeDir => cmChangeDir,
};

# Maximum line length inside TFileViewer
use constant {
  maxLineLength => 256,
};

# Palette for TClickTester
use constant {
  cpMousePalette => "\x07\x08",
};

1

__END__

=pod

=head1 NAME

TUI::Gadgets::Const - constants for gadget components

=head1 SYNOPSIS

  use TUI::Gadgets::Const qw( :all );

  # or import specific constant groups
  use TUI::Gadgets::Const qw( :cmXXXX );

=head1 DESCRIPTION

These module defines constants used by L<TUI::Vision> L<gadget|TUI::Gadgets> 
components.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used by gadget views to identify commands and events
specific to diagnostic and auxiliary user interface elements.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding gadget modules.

=head1 CONSTANTS

=head2 Gadget command constants (cmXXXX)

Command identifiers used by gadget components.

These values are delivered via C<< $event->{command} >> and are handled by
gadget views such as event viewers and diagnostic tools.

=head2 Gadget color palettes (cpXXXX)

Color palette constants used by gadget components.

These values define the color schemes for various gadget elements, such as the 
mouse pointer in L<TClickTester|TUI::Gadgets::TClickTester>.

=head2 History identifiers for dialogs (hlXXXX)

History identifiers used by gadget dialogs.

These values are used to track the history of user interactions within dialogs, 
such as the change directory dialog.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item * C<:cmXXXX> - gadget command identifiers

=item * C<:cpXXXX> - gadget color palettes

=item * C<:hlXXXX> - history identifiers for dialogs

=item * C<:all> - import all constants

=back

=head1 SEE ALSO

L<Gadgets|TUI::Gadgets>,
L<TEventViewer|TUI::Gadgets::EventViewer>,
L<TEvent|TUI::Drivers::Event>

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
