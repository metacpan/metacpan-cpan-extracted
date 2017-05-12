#!/bin/bash

(perldoc -tU ./lib/Perl/AfterFork.pm
 perldoc -tU $0
) >README

exit 0

=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item *

C<syscall( SYS_fork )> and C<syscall( SYS_getpid )> are needed for testing.

=item *

perl 5.8.0

=back

=head1 TESTED ON

=over 4

=item *

Linux 2.6 with glibc 2.3.3

=back

=cut
