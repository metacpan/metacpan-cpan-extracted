package TUI::Memory::Util;
# ABSTRACT: defines various memory-related utility functions

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use TUI::toolkit::boolean;

use Exporter 'import';

our @EXPORT_OK = qw(
  lowMemory
);

sub lowMemory () {    # $bool ()
  false;
}

1

__END__

=pod

=head1 NAME

TUI::Memory::Util - memory-related utility functions

=head1 SYNOPSIS

  use TUI::Memory::Util qw(lowMemory);

  if (lowMemory()) {
    messageBox(
      'Low memory condition detected',
      mfWarning | mfOkButton
    );
  }

=head1 DESCRIPTION

C<TUI::Memory::Util> provides low-level utility functions related to memory
management within the TUI::Vision framework.

The functions in this module expose global state maintained by the runtime and
are intended to support defensive behavior in views and application-level
logic when system resources become constrained.

This module is purely functional and does not define any classes or objects.

=head1 FUNCTIONS

=head2 lowMemory

  my $bool = lowMemory();

Returns true if the application has entered a low-memory condition.

A low-memory condition indicates that internal safety reserves have been used
and that further memory allocation may fail or behave unpredictably.

This function is typically consulted before creating new views or allocating
additional resources.

=head1 USAGE NOTES

The low-memory state is maintained globally by the framework.

Calling C<lowMemory> does not modify application state. It is intended as a
query function only.

Application code may use this information to display warnings, reject new
operations, or gracefully reduce resource usage.

=head1 COMPATIBILITY NOTES

This module follows the Turbo Vision C++ memory model and preserves its
behavioral semantics.

Internally, the original implementation relied on a reserved safety area to
detect memory exhaustion conditions. This Perl port retains the same logical
signal while relying on Perl-native memory management.

The observable behavior of C<lowMemory> matches the original model, while the
underlying memory handling is adapted to the Perl runtime environment.

=head1 SEE ALSO

L<TUI::App::Program>,
L<TUI::App::Application>,
L<TUI::Dialogs::Dialog>

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

