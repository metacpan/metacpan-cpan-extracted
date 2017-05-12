package POSIX::RT::Spawn;

use strict;
use warnings;
use parent qw(Exporter);

use XSLoader;

our $VERSION    = '0.11';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

our @EXPORT = qw(spawn);


1;

__END__

=head1 NAME

POSIX::RT::Spawn - Perl interface to the posix_spawn function

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

Does exactly the same thing as C<system LIST>, except the parent process
does not wait for the child process to exit. Also, the return value is the
child pid on success, or false on failure.

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

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=POSIX-RT-Spawn>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POSIX::RT::Spawn

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/posix-rt-spawn>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POSIX-RT-Spawn>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POSIX-RT-Spawn>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=POSIX-RT-Spawn>

=item * Search CPAN

L<http://search.cpan.org/dist/POSIX-RT-Spawn/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
