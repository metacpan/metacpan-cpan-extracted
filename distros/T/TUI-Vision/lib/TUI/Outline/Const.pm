package TUI::Outline::Const;
# ABSTRACT: constants for outline views

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  ovXXXX => [qw(
    ovExpanded
    ovChildren
    ovLast
  )],

  cmXXXX => [qw(
    cmOutlineItemSelected
  )],

  cpXXXX => [qw(
    cpOutlineViewer
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

# Outline viewer node flags (passed to TOutlineViewer::getGraph)

use constant {
  ovExpanded => 0x01,
  ovChildren => 0x02,
  ovLast     => 0x04,
};

# Commands

use constant {
  cmOutlineItemSelected => 301,
};

# TOutlineViewer palette layout

use constant cpOutlineViewer => "\x06\x07\x03\x08";

1

__END__

=pod

=head1 NAME

TUI::Outline::Const - constants for outline views

=head1 SYNOPSIS

  use TUI::Outline;

  my $flags = ovExpanded | ovChildren;

=head1 DESCRIPTION

This module defines the constants used by the L<TUI::Vision> outline
subsystem.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used by outline viewers and outlines to describe the
graph drawn for each node, to report commands, and to select palette entries.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding outline classes.

=head1 CONSTANTS

=head2 Outline node flags (ovXXXX)

Flags describing the state of a node while its graph is drawn. These flags may
be combined.

=over 4

=item * C<ovExpanded> (0x01)

Set if the node is expanded or has no children. If it is not set, the node has
children and is retracted.

=item * C<ovChildren> (0x02)

Set if the node has children and is expanded.

=item * C<ovLast> (0x04)

Set if the node is the last child of its parent.

=back

=head2 Command constants (cmXXXX)

=over 4

=item * C<cmOutlineItemSelected> (301)

Command identifier for the selection of an outline item. The outline viewers
of this port do not send this command.

=back

=head2 Palette identifiers (cpXXXX)

=over 4

=item * C<cpOutlineViewer>

Palette layout of C<TOutlineViewer>, used by its C<getPalette> method.

=back

=head1 EXPORT TAGS

Constants are exported using tag-based export groups corresponding to the
functional groups described above.

An additional C<:all> export tag is provided to import all constants at once.

=head1 SEE ALSO

L<TUI::Outline>

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
