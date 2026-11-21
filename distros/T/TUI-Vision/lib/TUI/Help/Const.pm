package TUI::Help::Const;
# ABSTRACT: constants for the help system

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  MAXHELPTOPICID
);

our %EXPORT_TAGS = (

  cXXXX => [qw(
    cHelpViewer
    cHelpWindow
  )],

  wrapXXXX => [qw(
    undefined
    wrapping
    notWrapping
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

# When building helpfiles for 16-bit programs, a topic should never
# be assigned a number higher than 16379. In 32-bit programs there
# is no such limitation, but it is recommended that the numbers used
# be kept low for efficiency reasons.
use constant MAXHELPTOPICID => 16379 << 16;

use constant {
  undefined   => 0,
  wrapping    => 1,
  notWrapping => 2,
};

use constant {
  cHelpViewer => "\x06\x07\x08",
  cHelpWindow => "\x80\x81\x82\x83\x84\x85\x86\x87",
};

1

__END__

=pod

=head1 NAME

TUI::Help::Const - constants for the help system

=head1 SYNOPSIS

  use TUI::Help;

=head1 DESCRIPTION

Defines the help-topic ID limit from the original Borland help compiler and
the palette strings from the Turbo Vision help-base design.
No constants are exported by default.

=head1 CONSTANTS

=head2 MAXHELPTOPICID

Maximum topic ID accepted by the help-topic parser. The original Borland
help compiler defines C<16379>; this port uses that value shifted left by 16 bits, so the
constant is C<16379 << 16> (C<1073414144>).

=head2 Help palettes (cXXXX)

=over

=item cHelpViewer

Help viewer palette: C<"\x06\x07\x08">.

=item cHelpWindow

Help window palette: C<"\x80\x81\x82\x83\x84\x85\x86\x87">.

=back

=head2 Paragraph wrapping states

=over

=item undefined

C<0>. No paragraph wrapping mode has been selected yet.

=item wrapping

C<1>. The current paragraph uses word wrapping.

=item notWrapping

C<2>. The current paragraph preserves line breaks without word wrapping.

=back

=head1 EXPORT TAGS

=over

=item :cXXXX

Imports C<cHelpViewer> and C<cHelpWindow>.

=item :wrapXXXX

Imports C<undefined>, C<wrapping>, and C<notWrapping>.

=item :all

Imports all constants, including C<MAXHELPTOPICID>, C<undefined>,
C<wrapping>, and C<notWrapping>.

=back

Every constant may also be imported individually.

=head1 SEE ALSO

L<TUI::Help>, L<THelpFile|TUI::Help::HelpFile>,
L<TUI::Manual::Reference::Constants>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file,
which is part of the distribution).

=cut
