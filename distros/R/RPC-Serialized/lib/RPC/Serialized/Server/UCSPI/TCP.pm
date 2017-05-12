package RPC::Serialized::Server::UCSPI::TCP;
{
  $RPC::Serialized::Server::UCSPI::TCP::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Server::UCSPI';

use RPC::Serialized::Exceptions;

sub subject {
    my $self = shift;

    my $remote = $ENV{TCPREMOTEINFO}
        or throw_authz 'TCPREMOTEINFO not set';

    return $remote;
}

1;

# ABSTRACT: RPC server managed by DJB's ucspi-tpc


__END__
=pod

=head1 NAME

RPC::Serialized::Server::UCSPI::TCP - RPC server managed by DJB's ucspi-tpc

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 use RPC::Serialized::Server::UCSPI::TCP;
 
 # set up the new server
 my $s = RPC::Serialized::Server::UCSPI::TCP->new;
 
 # begin a single-process loop handling requests on STDIN and STDOUT
 $s->process;

=head1 DESCRIPTION

This module provides an extension to L<RPC::Serialized> which enhances support
for Dan Bernstein's C<ucspi-tcp> network services system.

In C<ucspi>-land, servers communicate using Standard Input and Standard
Output, so things are very simple. His services system takes care of setting
up a listening network socket, and forking off child handlers. Those child
handlers are simple setup scripts just like that shown in the L</SYNOPSIS>
above.

Within the C<examples> directory of this distribution, there is an example
C<tcpserver> startup script which uses this module.

There is no additional server configuration necessary, although you can of
course supply arguments to C<new()> as described in the L<RPC::Serialized>
manual page.

This module provides support for using the C<TCPREMOTEINFO> environment
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

