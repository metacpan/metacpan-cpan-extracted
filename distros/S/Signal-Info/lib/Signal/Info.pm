package Signal::Info;
$Signal::Info::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: A wrapper around siginfo_t

__END__

=pod

=encoding UTF-8

=head1 NAME

Signal::Info - A wrapper around siginfo_t

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This class represents a POSIX C<siginfo_t> structure. It is typically not created by an end-user, but returned by (XS) modules.

=head1 METHODS

=head2 new

This creates a new (empty) siginfo object.

=head2 signo

The signal number.

=head2 code

The signal code.

=head2 errno

If non-zero, an errno value associated with this signal.

=head2 pid

Sending process ID.

=head2 uid

Real user ID of sending process.

=head2 status

Exit value or signal.

=head2 band

Band event for SIGPOLL.

=head2 value

Signal integer value.

=head2 ptr

Signal pointer value (as an unsigned)

=head2 addr

Address of faulting instruction.

=head2 fd

File descriptor associated with the signal. This may not be available everywhere.

=head2 timerid

Timer ID of POSIX real-time timers. This may not be available everywhere.

=head2 overrun

Timer overrun count of POSIX real-time timers. This may not be available everywhere.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
