package Proc::Safetynet;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.04';

use Proc::Safetynet::Supervisor;
use Proc::Safetynet::Event;
use Proc::Safetynet::Program;
use Proc::Safetynet::ProgramStatus;


1;

__END__

=head1 NAME

Proc::Safetynet - POE-based utility for supervising processes

=head1 SYNOPSIS

    use Proc::Safetynet;
    use Proc::Safetynet::Program::Storage::TextFile;

    # load programs
    my $programs = Proc::Safetynet::Program::Storage::TextFile->new(
        file            => "/etc/my.programs",
    );
    $programs->reload;

    # start supervisor
    my $supervisor = Proc::Safetynet::Supervisor->spawn(
        binpath         => "/bin:/usr/bin",
        programs        => $programs,
    );

    POE::Kernel->run();

=head1 DESCRIPTION

L<Proc::Safetynet> is a utility framework for building programs that
supervises or "babysits" other processes. Supervision tasks can include
process management (start / stop) and program provisioning (add / remove
applications).

L<Proc::Safetynet> is especially useful for monitoring and auto-restarting 
long-running server programs (e.g. FastCGI scripts).

=head1 SEE ALSO

See the accompanying C<bin/safetynetd.pl> script as part of the 
L<Proc::Safetynet> distribution for the actual supervisor daemon.
The distribution also includes sample configuration files under C<etc>.

L<Proc::Safetynet> heavily borrows concepts and implementation details
from the Supervisord project - http://supervisord.org

=head1 AUTHOR

Dexter Tad-y, <dexterbt1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dexter Tad-y

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
