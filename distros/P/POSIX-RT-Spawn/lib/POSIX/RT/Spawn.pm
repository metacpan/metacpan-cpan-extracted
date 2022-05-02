package POSIX::RT::Spawn;

use strict;
use warnings;

use Exporter qw(import);
use XSLoader;

our $VERSION    = '0.12';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

our @EXPORT = qw(spawn);


1;

__END__

=head1 NAME

POSIX::RT::Spawn - interface to the posix_spawn function

=head1 SYNOPSIS

  use POSIX::RT::Spawn;

  my $pid = spawn 'command', 'arg1', 'arg2'
      or die "failed to spawn: $!";
  waitpid $pid, 0;
  die "command failed with status: ", $?>>8 if $?;

=head1 DESCRIPTION

The C<POSIX::RT::Spawn> module provides an interface to the posix_spawn(2)
function for creating new processes.

=head1 FUNCTIONS

=head2 spawn

  $pid = spawn 'echo', 'hello world'

Does exactly the same thing as C<system LIST>, except the parent process does
not wait for the child process to exit. Also, the return value is the child
pid on success, or false on failure.

See L<perlfunc/system> for more details.

=head1 SEE ALSO

L<http://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_spawn.html>

=head1 TODO

=over

=item *

Allow the user to alter posix_spawn settings using package variables, e.g.
  $POSIX::RT::Spawn::Flags{RESETIDS} = 1
or
  $POSIX::RT::Spawn::Flags |= &POSIX_SPAWN_RESETIDS

=item *

Allow the user to lexically replace the ops that use fork/exec (e.g.
backticks, open, system) with versions that use posix_spawn.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2022 gray <gray at cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
