package TUI::ColorSel::Const;
# ABSTRACT: constants for the color dialog components

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (
  cmXXXX => [qw(
    cmColorForegroundChanged
    cmColorBackgroundChanged
    cmColorSet
    cmNewColorItem
    cmNewColorIndex
    cmSaveColorIndex
  )],

  csXXXX => [qw(
    csBackground
    csForeground
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

# Color command codes
use constant {
  cmColorForegroundChanged => 71,
  cmColorBackgroundChanged => 72,
  cmColorSet               => 73,
  cmNewColorItem           => 74,
  cmNewColorIndex          => 75,
  cmSaveColorIndex         => 76,
};

# enum ColorSel
use constant { 
  csBackground => 0,
  csForeground => 1,
};

1

__END__

=pod

=head1 NAME

TUI::ColorSel::Const - constants for color dialog components

=head1 SYNOPSIS

  use TUI::ColorSel::Const qw(:all);

  # or import specific constant groups
  use TUI::ColorSel::Const qw(:cmXXXX);

=head1 DESCRIPTION

C<TUI::ColorSel::Const> defines constants used by L<TUI::Vision> color 
selection dialog components.

=head1 CONSTANTS

=head2 Color selection command constants (cmXXXX)

These constants represent the command codes used by the color selection dialog 
components. 

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item * C<:cmXXXX> - color selection command identifiers

=item * C<:csXXXX> - color selection constants

=item * C<:all> - import all constants

=back

=head1 SEE ALSO

L<ColorSel|TUI::ColorSel>,
L<TColorDialog|TUI::ColorSel::ColorDialog>

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
