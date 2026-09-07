package Punk::Challenge::Solver;

use 5.010;
use strict;
use warnings;
use Punk::Challenge ();    # one dist, one bootstrap

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Challenge::Solver - solve a puzzle here, for the tests and the command line

=head1 SYNOPSIS

    my $solution = Punk::Challenge::Solver::solve($puzzle);
    my $maybe    = Punk::Challenge::Solver::solve($puzzle, max => 100_000);

=head1 DESCRIPTION

Finds the nonce for a puzzle issued by L<Punk::Challenge::Token>, the way the
browser does. It exists for the test suite and for C<punk challenge solve>,
so an operator can clear a deployment from C<curl>.

B<Never call this from a handler.> A solver reachable from the request path
is a denial of service on yourself: every request that reaches it costs the
server the CPU the puzzle was designed to charge the client. Nothing under
the plugin calls it, and it should stay that way.

=head1 FUNCTIONS

=head2 solve($puzzle, %opts)

The solution string: the puzzle, a dot, and the first nonce from zero whose
hash begins with the puzzle's C<bits> zero bits. The difficulty is read from
the puzzle; the MAC is not checked, because the solver has no secret. Croaks
on a string that is not a puzzle.

C<max> bounds the nonces tried, and the return is C<undef> when it is
reached. Expected work is C<2 ** bits> hashes.

=head1 SEE ALSO

L<Punk::Challenge::Token>, L<Punk::Plugin::Challenge>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
