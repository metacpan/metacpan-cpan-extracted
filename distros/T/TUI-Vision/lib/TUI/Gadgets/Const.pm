package TUI::Gadgets::Const;
# ABSTRACT: constants for gadget components

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (
  cmXXXX => [qw(
    cmFndEventView
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

use constant {
  cmFndEventView => 114
};

1

__END__

=pod

=head1 NAME

TUI::Gadgets::Const - constants for gadget components

=head1 SYNOPSIS

  use TUI::Gadgets::Const qw(:all);

  # or import specific constant groups
  use TUI::Gadgets::Const qw(:cmXXXX);

=head1 DESCRIPTION

C<TUI::Gadgets::Const> defines constants used by TUI::Vision gadget components.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used by gadget views to identify commands and events
specific to diagnostic and auxiliary user interface elements.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding gadget modules.

=head1 CONSTANTS

=head2 Gadget command constants (cmXXXX)

Command identifiers used by gadget components.

These values are delivered via C<$event-E<gt>{command}> and are handled by
gadget views such as event viewers and diagnostic tools.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:cmXXXX> - gadget command identifiers

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::Gadgets>,
L<TUI::Gadgets::EventViewer>,
L<TUI::Drivers::Event>

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
