package RPC::Serialized::Server::NetServer::SSL;
{
  $RPC::Serialized::Server::NetServer::SSL::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Server::NetServer';

sub new {
    my $class = shift;
    $class->SUPER::new(@_, { net_server => { proto => 'ssl' } });
}

sub post_accept_hook {
    my $self = shift;

    $self->rs->ifh( $self->{server}->{client} );
    $self->rs->ofh( $self->{server}->{client} );
    $self->rs->ofh->autoflush(1);

    return $self;
}

1;

# ABSTRACT: Run an RPC server using IO::Socket::SSL


__END__
=pod

=head1 NAME

RPC::Serialized::Server::NetServer::SSL - Run an RPC server using IO::Socket::SSL

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 use RPC::Serialized::Server::NetServer::SSL;
 
 my $s = RPC::Serialized::Server::NetServer::SSL->new({
     net_server => { port => 1234 },
 });
 
 # note that $s isa Net::Server::PreFork, not an RPC::Serialized

 s->run;
     # server process is now looping and waiting for RPC (like Apache prefork)
     # the default port number for Net::Server is 20203
 
 
 # alternatively, if you have an external configuration file which
 # Config::Any can load, try the following:
 
 $s = RPC::Serialized::Server::NetServer::SSL->new('/path/to/config/file');
 
 # you can also combine config file and hash reference arguments

=head1 DESCRIPTION

This module provides a bridge between L<RPC::Serialized> and L<Net::Server>,
meaning you can easily run an RPC server without installing any additional
daemonizing tools onto your system. The module sets up a basic PreFork server,
which runs much like Apache in PreFork mode, and you can override any of the
default configuration to C<Net::Server>.

The module uses a Secure Socket Layer (SSL) to encapsulate the normal
operation, which is otherwise identical to that of the
L<RPC::Serialized::Server::NetServer> module.

It is strongly recommended that you at least once read through the
L<Net::Server> manual page and the L<Net::Server::PreFork> manual page, to
familiarize yourself with the configuration options. You do not need to worry
much about the client connection processing or hooks, because that is dealt
with inside of this module.

=head1 CONFIGURATION

In addition to the normal Net::Server parameters, any of the SSL parameters
from L<IO::Socket::SSL> may also be specified in the C<net_server> config
hash.

Most of the defaults for C<Net::Server> have been left alone, because they are
reasonably sane and easy to override using the syntax shown in L</SYOPSIS>,
above. Here are the non-standard settings:

=over 4

=item C<log_level> is set to C<4>

This means you get a little more detail from the parent C<Net::Server> process
about its child handlers, for instance when they are started.

=item C<syslog_facility> is set to C<local1>

This is merely so that logging messages from this application are available
separately to your other standard system logs. Most good Syslog daemons (e.g.
C<syslog-ng> can flexibly handle each facility.

=back

=head2 Things you might want to configure

By default the server will remain in the foreground, and not fork or detach
from its parent process to become a daemon. Check the C<background> and
C<setsid> options if you would like a proper background daemon running.

The logging output will go to STDERR, so to change this set the C<log_file>
option. The C<Net::Server> manual page describes the values available.

For performance tweaking, you might want to alter some of the
C<Net::Server::PreFork> settings. Again, see the manual page for that module
for further details.

=head1 RUNNING THE SERVER

Once you have instantiated a new server object using C<new()>, there is just
one method call to make to begin the processing loop:

 $s->run;

This will fork the child handlers, and begin running as a server. Note that
this is a method on the C<Net::Server> object and not C<RPC::Serialized>; it
wraps the C<process()> call normally issued to that module in other servers.

=head1 THANKS

Kindly submitted by Oleg A. Mamontov.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

