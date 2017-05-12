package Perl::AfterFork;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Perl::AfterFork', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Perl::AfterFork - reinitializes Perl's notion of $$ and getppid()

=head1 SYNOPSIS

  use Perl::AfterFork;
  &Perl::AfterFork::reinit_pid;
  &Perl::AfterFork::reinit_ppid;
  &Perl::AfterFork::reinit_pidstatus;
  &Perl::AfterFork::reinit;

=head1 DESCRIPTION

Using Perl's C<fork()> command or your libc's C<fork()> function or even
your operating system's C<fork> syscall does not do the same thing.

Since a process' PID does not change during it's life time Perl caches the
result of the C<getpid> syscall using the once fetched PID each time C<$$>
is used. Hence after a successful C<fork()> the internal PID-cache must be
invalidated. The same argument is valid for C<glibc>. It caches the
C<getpid(2)> as well.

As for C<getppid(2)>, Perl is even caching that. In my opinion Perl is
doing wrong when caching the C<getppid(2)> result at all since it can
change without further notice when the parent process dies.

Further Perl maintains an internal cache of spawned children for it's
C<waitpid> implementation.

All these cached information can be reinitialized with this module.

=over 4

=item B<reinit_pid>

reinitializes the PID-cache

=item B<reinit_ppid>

reinitializes the PPID-cache

=item B<reinit_pidstatus>

reinitializes the waitpid-cache

=item B<reinit>

reinitializes all 3 at once

=back

=head1 EXPORT

Not an Exporter.

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
