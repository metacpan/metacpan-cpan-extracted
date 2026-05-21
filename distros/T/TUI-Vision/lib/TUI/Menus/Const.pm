package TUI::Menus::Const;
# ABSTRACT: constants for menu classes

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
    cpMenuView
    cpStatusLine
  )],

  menuAction => [qw(
    doNothing
    doSelect
    doReturn
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

use constant cpMenuView => "\x02\x03\x04\x05\x06\x07";

use constant cpStatusLine => "\x02\x03\x04\x05\x06\x07";

# Constants for menuAction
use constant {
  doNothing => 0,
  doSelect  => 1,
  doReturn  => 2,
};

1

__END__

=pod

=head1 NAME

TUI::Menus::Const - constants for menu components

=head1 SYNOPSIS

  use TUI::Menus::Const qw(:all);

  # or import specific constant groups
  use TUI::Menus::Const qw(:cpXXXX :menuAction);

=head1 DESCRIPTION

C<TUI::Menus::Const> defines constants used by TUI::Vision menu components.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used by menu views, menu boxes, menu bars, and status
lines to control appearance and menu action handling.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in higher-level modules such as C<TUI::Menus>,
C<TMenuView>, C<TMenuBar>, and C<TStatusLine>.

=head1 CONSTANTS

=head2 Menu palette layouts (cpXXXX)

Palette layouts used by menu-related views.

These constants define the color layout for menu views and status lines.

=head2 Menu action constants (menuAction)

Action identifiers used internally by menu processing logic.

These constants control how menu selections are handled, such as whether an
action is executed immediately, ignored, or returned to the caller.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:cpXXXX> - menu palette layouts

=item *

C<:menuAction> - menu action identifiers

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::Menus>,
L<TUI::Menus::MenuView>,
L<TUI::Menus::MenuBar>,
L<TUI::Menus::StatusLine>

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