package TUI::Const;
# ABSTRACT: Miscellaneous system-wide configuration parameters.

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  INT_MAX
  UINT_MAX

  EOS

  maxFindStrLen
  maxReplaceStrLen
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use constant {
  INT_MAX  => ~0 >> 1,
  UINT_MAX => ~0,
};

use constant {
  EOS => q{},
};

use constant {
  maxFindStrLen     => 80,
  maxReplaceStrLen  => 80,
};

1

__END__

=pod

=head1 NAME

TUI::Const - system-wide configuration constants

=head1 SYNOPSIS

  use TUI::Const qw(:all);

  # or import specific constants
  use TUI::Const qw(INT_MAX UINT_MAX);

=head1 DESCRIPTION

C<TUI::Const> defines system-wide constants used throughout the TUI::Vision
framework.

The constants in this module provide common limits, sentinel values, and size
constraints that are shared across multiple subsystems such as objects,
collections, dialogs, and utility code.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding higher-level modules that
make use of them.

=head1 CONSTANTS

=head2 Integer limit constants

Constants defining platform-independent integer limits.

These values are used to calculate size limits and bounds in low-level code.

=head2 String and sentinel constants

Constants defining sentinel values and string-related limits.

These values are used internally by dialog and utility components.

=head1 EXPORT TAGS

This module provides the following export behavior:

=over

=item *

Individual constants may be imported explicitly.

=item *

The C<:all> tag imports all constants defined by this module.

=back

=head1 SEE ALSO

L<TUI::Objects::Const>,
L<TUI::StdDlg::Const>,
L<TUI::Dialogs::Const>

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
