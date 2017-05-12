package Process::Infinite;

use 5.00503;
use strict;
use Process ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.30';
	@ISA     = 'Process';
}

1;

__END__

=pod

=head1 NAME

Process::Infinite - Base class for processes that do not naturally end

=head1 DESCRIPTION

C<Process::Infinite> is a base class for L<Process> objects that will
not naturally finish without provocation from outside the process.

Examples of this are system "daemons" and servers of various types.

At the present time this class is purely indicative. It contains no
additional functionality.

=head2 Stopping Your Process

When writing a C<Process::Infinite> class, the most important thing to
note is how you plan to shutdown your process. This will vary from
case to case but the general implementation tends to be the same.

Your C<run> class consists of a main loop. How often this loop will
fire will vary, but it should generally fire at least once a second
or so.

The loop will check a flag or do some other cheap task to know if it
is time to stop, then shutdown gracefully. You will then add some form
of signal handler that sets the shutdown flag.

On UNIX platforms, you should at the very least add a signal handler
for C<SIGTERM>, as this is what will be sent to you by the operating
system when it shuts down. (If you don't respond in a few seconds, it
will then C<SIGKILL> and take out your running process by force, with
no chance for you to shut down gracefully)

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
