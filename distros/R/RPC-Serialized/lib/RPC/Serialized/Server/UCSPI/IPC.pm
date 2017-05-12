package RPC::Serialized::Server::UCSPI::IPC;
{
  $RPC::Serialized::Server::UCSPI::IPC::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Server::UCSPI';

use RPC::Serialized::Exceptions;

sub subject {
    my $self = shift;

    my $uid  = $ENV{IPCREMOTEEUID}
        or throw_authz 'IPCREMOTEEUID not set';

    my $username = getpwuid($uid)
        or throw_authz 'getpwuid $uid failed';

    return $username;
}

1;

# ABSTRACT: RPC server managed by ucspi-ipc


__END__
=pod

=head1 NAME

RPC::Serialized::Server::UCSPI::IPC - RPC server managed by ucspi-ipc

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 use RPC::Serialized::Server::UCSPI::IPC;
 
 # set up the new server
 my $s = RPC::Serialized::Server::UCSPI::IPC->new;
 
 # begin a single-process loop handling requests on STDIN and STDOUT
 $s->process;

=head1 DESCRIPTION

This module provides an extension to L<RPC::Serialized> which enhances support
for the C<ucspi-ipc> network services system, produced by I<SuperScript
Technology, Inc.>.

In C<ucspi>-land, servers communicate using Standard Input and Standard
Output, so things are very simple. The services system takes care of setting
up a listening network socket, and forking off child handlers. Those child
handlers are simple setup scripts just like that shown in the L</SYNOPSIS>
above.

Within the C<examples> directory of this distribution, there is an example
C<tcpserver> startup script which can be easily adapted to use this module.

There is no additional server configuration necessary, although you can of
course supply arguments to C<new()> as described in the L<RPC::Serialized>
manual page.

This module provides support for using the C<IPCREMOTEINFO> environment
variable in the call authorization phase of C<RPC::Serialized>. Although not
well documented, this is fully working and there are example scripts in this
distribution.

=head1 THANKS

This module is a derivative of C<YAML::RPC>, written by C<pod> and Ray Miller,
at the University of Oxford Computing Services. Without their brilliant
creation this system would not exist.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

