package TUI::Validate::Const;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vsXXXX => [qw(
    vsOk
    vsSyntax
  )],

  voXXXX => [qw(
    voFill
    voTransfer
    voReserved
  )],

  vtXXXX => [qw(
    vtDataSize
    vtSetData
    vtGetData
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

# TValidator Status constants

use constant {
  vsOk     =>  0,
  vsSyntax =>  1,    # Error in the syntax of either a TPXPictureValidator
};                   # or a TDBPictureValidator

# Validator option flags

use constant {
  voFill     => 0x0001,
  voTransfer => 0x0002,
  voReserved => 0x00fc,
};

# TVTransfer constants

use constant {
  vtDataSize => 0,
  vtSetData  => 1,
  vtGetData  => 2,
};

1

__END__

=pod

=head1 NAME

TUI::Validate::Const - constants for validator components

=head1 SYNOPSIS

  use TUI::Validate::Const qw(:all);

  # or import specific constant groups
  use TUI::Validate::Const qw(:vsXXXX :voXXXX :vtXXXX);

=head1 DESCRIPTION

C<TUI::Validate::Const> defines constants used by validation components
within the TUI::Vision framework.

The constants in this module describe validator status codes, option flags,
and data transfer operations. They are grouped by purpose and exported via
tag-based export groups.

This module only defines constants. The semantic meaning and practical usage
of these values is implemented and documented in the corresponding validator
classes.

=head1 CONSTANTS

=head2 Validator status constants (vsXXXX)

Status codes returned by validators to indicate validation results.

These values are typically used to signal success or specific validation
errors, such as syntax errors detected by picture-based validators.

=head2 Validator option flags (voXXXX)

Option flags controlling validator behavior.

These flags are used to configure validation and data transfer semantics,
for example whether data should be filled or transferred.

=head2 Validator transfer constants (vtXXXX)

Constants defining data transfer operations between validators and
associated data structures.

These values are used internally by validators to identify transfer modes
such as setting or retrieving data.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:vsXXXX> - validator status constants

=item *

C<:voXXXX> - validator option flags

=item *

C<:vtXXXX> - validator transfer constants

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::Validate>,
L<TUI::Objects>,
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
