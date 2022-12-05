# -*- perl -*-
#
#  Net::Server::Thread - Net::Server personality
#
#  Copyright (C) 2010-2022
#
#    Paul Seamons <paul@seamons.com>
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
################################################################

package Net::Server::Thread;

use strict;
use base qw(Net::Server::Fork);
use Net::Server::SIG qw(register_sig check_sigs);
use Socket qw(SO_TYPE SOL_SOCKET SOCK_DGRAM);
eval { require threads };
$@ && die "threads are required to run a server of type Net::Server::Thread";

sub net_server_type { __PACKAGE__ }

sub options {
    my $self = shift;
    my $ref  = $self->SUPER::options(@_);
    my $prop = $self->{'server'};
    $ref->{$_} = \$prop->{$_} for qw(max_servers);
    return $ref;
}

sub loop {
    my $self = shift;
    my $prop = $self->{'server'};

    $self->register_sig_pass;

    # register some of the signals for safe handling
    register_sig(PIPE => 'IGNORE',
                 INT  => sub { $self->server_close() },
                 TERM => sub { $self->server_close() },
                 QUIT => sub { $self->server_close() },
                 HUP  => sub { $self->sig_hup() },
                );

    while (1) {

        threads->yield();

        while (threads->list() > $prop->{'max_servers'}){
            select undef, undef, undef, .5; # block for a moment (don't look too often)
            check_sigs();
            threads->yield();
        }

        $self->pre_accept_hook;

        if (! $self->accept()) {
            last if $prop->{'_HUP'};
            last if $prop->{'done'};
            next;
        }

        $self->pre_thread_hook;

        threads->new(sub { $self->run_client_connection })->detach;

        # parent
        delete($prop->{'client'}) if !$prop->{'udp_true'};
    }
}

sub close_children {
    my $self = shift;
    my $prop = $self->{'server'};

    return unless $prop->{'children'} && scalar keys %{ $prop->{'children'} };

    foreach my $thr (threads->list) {
        $thr->detach if ! $thr->is_detached;
        $thr->kill(15) if $thr->is_running;
    }

    check_sigs(); # since we have captured signals - make sure we handle them

    register_sig(PIPE => 'DEFAULT',
                 INT  => 'DEFAULT',
                 TERM => 'DEFAULT',
                 QUIT => 'DEFAULT',
                 HUP  => 'DEFAULT',
                 CHLD => 'DEFAULT',
                 );
}

sub pre_accept_hook {};

sub accept {
    my $self = shift;
    my $prop = $self->{'server'};

    # block on trying to get a handle (select created because we specified multi_port)
    my @socks = $prop->{'select'}->can_read(2);
    if (check_sigs()) {
        return undef if $prop->{'_HUP'};
        return undef if ! @socks; # don't continue unless we have a connection
    }

    my $sock = $socks[rand @socks];
    return undef if ! defined $sock;

    # check if this is UDP
    if (SOCK_DGRAM == $sock->getsockopt(SOL_SOCKET,SO_TYPE)) {
        $prop->{'udp_true'} = 1;
        $prop->{'client'}   = $sock;
        $prop->{'udp_peer'} = $sock->recv($prop->{'udp_data'}, $sock->NS_recv_len, $sock->NS_recv_flags);

    # Receive a SOCK_STREAM (TCP or UNIX) packet
    } else {
        delete $prop->{'udp_true'};
        $prop->{'client'} = $sock->accept() || return;
    }
}

sub run_client_connection {
    my $self = shift;

    $SIG{'INT'} = $SIG{'TERM'} = $SIG{'QUIT'} = sub { threads->exit(0) };
    $SIG{'HUP'} = $SIG{'CHLD'} = 'DEFAULT';
    $SIG{'PIPE'} = 'IGNORE';

    $self->SUPER::run_client_connection;
}

sub run_dequeue { die "run_dequeue: virtual method not defined" }

sub pre_thread_hook {}

1;

__END__

=head1 NAME

Net::Server::Thread - Net::Server personality

=head1 SYNOPSIS

    use base qw(Net::Server::Thread);

    sub process_request {
        #...code...
    }

    __PACKAGE__->run();

=head1 DESCRIPTION

Please read the pod on Net::Server first.  This module is a
personality, or extension, or sub class, of the Net::Server module.

This personality binds to one or more ports and then waits for a
client connection.  When a connection is received, the server spawns a
new thread.  The thread handles the request and then closes.

Because this Net::Server flavor spawns and destroys a thread for each
request, it really should only be used where the processing of each
request may be lengthy or involved.  If short and light request are
used, perl may not voluntarily give back the used memory.  This is
highly system dependent.

=head1 ARGUMENTS

=over 4

=item check_for_dead

Number of seconds to wait before looking for dead children.  This only
takes place if the maximum number of child processes (max_servers) has
been reached.  Default is 60 seconds.

=item max_servers

The maximum number of children to fork.  The server will not accept
connections until there are free children. Default is 256 children.

=back

=head1 CONFIGURATION FILE

See L<Net::Server>.

=head1 PROCESS FLOW

Process flow follows Net::Server until the post_accept phase.  At this
point a child is forked.  The parent is immediately able to wait for
another request.  The child handles the request and then exits.

=head1 HOOKS

The Fork server has the following hooks in addition to the hooks
provided by the Net::Server base class.  See L<Net::Server>

=over 4

=item C<$self-E<gt>pre_accept_hook()>

This hook occurs just before the accept is called.

=item C<$self-E<gt>pre_thread_hook()>

This hook occurs just after accept but before the fork.

=item C<$self-E<gt>post_accept_hook()>

This hook occurs in the child after the accept and fork.

=back

=head1 TO DO

See L<Net::Server>

=head1 AUTHOR

Paul Seamons <paul@seamons.com>

=head1 SEE ALSO

Please see also
L<Net::Server::INET>,
L<Net::Server::Fork>,
L<Net::Server::PreFork>,
L<Net::Server::PreForkSimple>,
L<Net::Server::MultiType>,
L<Net::Server::SIG>
L<Net::Server::Single>

=cut

