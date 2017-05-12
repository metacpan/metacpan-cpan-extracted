package Proc::Launcher::Supervisor;
use strict;
use warnings;

our $VERSION = '0.0.37'; # VERSION

use Moo;
use MooX::Types::MooseLike::Base qw(Bool Str Int InstanceOf HashRef);

has 'monitor_delay' => ( is       => 'rw',
                         isa      => Int,
                         default  => 15,
                     );

has 'manager'       => ( is       => 'rw',
                         isa      => InstanceOf['Proc::Launcher::Manager'],
                         required => 1,
                     );

sub monitor {
    my ( $self ) = @_;

    sleep 5;

    while ( 1 ) {
        $self->manager->start();
        sleep $self->monitor_delay;
    }
}

1;

__END__

=head1 NAME

Proc::Launcher::Supervisor - restart watched processes that have exited


=head1 VERSION

version 0.0.37

=head1 DESCRIPTION

This is a tiny module that's designed for use with panctl and
L<Proc::Launcher>, where it is forked off and run as a separate process.

=head1 ATTRIBUTES

=over 8

=item monitor_delay

Number of seconds to sleep before attempting to restart any daemons
that aren't running.  Defaults to 15.

=item manager

A L<Proc::Launcher::Manager> object, with daemons already registered.
The supervisor will call the manager's start method at regular
intervals.  This will start any daemons that are not found running.

=back

=head1 METHODS

=over 8

=item $obj->monitor()

This tiny class contains only this one method.

It will repeatedly sleep for a configured period of time (default 15
seconds), and then call start_all() on the manager object.  This will
result in restarting any processes that have stopped.

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, VVu@geekfarm.org
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
