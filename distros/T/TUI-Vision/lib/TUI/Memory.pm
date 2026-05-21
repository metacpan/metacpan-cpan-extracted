package TUI::Memory;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Memory::Util;

sub import {
  my $target = caller;
  TUI::Memory::Util->import::into( $target, qw( lowMemory ) );
}

sub unimport {
  my $caller = caller;
  TUI::Memory::Util->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Memory - Memory utilities for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Memory;

=head1 DESCRIPTION

TUI::Memory provides memory-related utility functions for the
TUI::Vision framework. In the original Turbo Vision architecture,
this subsystem offered lightweight helpers for detecting low-memory
conditions and performing diagnostic checks.

This module re-exported:

=over 4

=item * L<Util|TUI::Memory::Util> -
Utility functions such as C<lowMemory> for memory monitoring.

=back

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
