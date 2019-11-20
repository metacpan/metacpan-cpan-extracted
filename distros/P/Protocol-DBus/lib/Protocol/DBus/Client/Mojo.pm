package Protocol::DBus::Client::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::IOAsync - D-Bus with L<IO::Async>

=head1 SYNOPSIS

See L<Protocol::DBus::Client::AnyEvent>.

=head1 DESCRIPTION

This module provides an interface between L<Mojo::IOLoop> and
L<Protocol::DBus::Client>. It subclasses L<Protocol::DBus::Client::EventBase>.

L<Mojolicious>-based applications can use this module to interface with
D-Bus.

=cut

#----------------------------------------------------------------------

our @ISA;

use parent qw( Protocol::DBus::Client::EventBase );

use Mojo::IOLoop ();

#----------------------------------------------------------------------

=head1 INTERFACE

This module’s interface is identical to that of
L<Protocol::DBus::Client::AnyEvent>. See that module for more details.

=cut

sub system {
    return __PACKAGE__->_create_system();
}

sub login_session {
    return __PACKAGE__->_create_login_session();
}

sub _initialize {
    my ($self, $y, $n) = @_;

    my $dbus = $self->{'db'};

    my $fileno = $dbus->fileno();

    open my $socket, '+>&=' . $fileno;
    $self->{'socket'} = $socket;

    my $is_write_listening;

    my $reactor = Mojo::IOLoop->singleton->reactor();

    my $cb = sub {
        if ( $dbus->initialize() ) {
            $reactor->remove($socket);

            $y->();
        }

        # It seems unlikely that we’d need a write watch here.
        # But just in case …
        elsif ($dbus->init_pending_send()) {
            $is_write_listening ||= do {
                $reactor->watch($socket, 1, 1);
                1;
            };
        }
        else {
            $reactor->watch($socket, 1, 0);
        }
    };

    $reactor->io( $socket, $cb );

    $cb->();
}

sub _flush_send_queue {
    my ($dbus, $reactor, $socket) = @_;

    $dbus->flush_write_queue() && $reactor->watch($socket, 1, 0);

    return;
}

sub _set_watches_and_create_messenger {
    my ($self) = @_;

    my $dbus = $self->{'db'};

    my $fileno = $dbus->fileno();

    my $read_cb = $self->_create_get_message_callback();

    my $reactor = Mojo::IOLoop->singleton->reactor();
    my $socket = $self->{'socket'};

    $reactor->io(
        $self->{'socket'},
        sub {
            (undef, my $writable) = @_;

            if ($writable) {
                my $r = Mojo::IOLoop->singleton->reactor();
                _flush_send_queue($r, $reactor, $socket);
            }
            else {
                $read_cb->();
            }
        },
    )->watch( $socket, 1, $dbus->pending_send() );

    return sub {
        if ($dbus->pending_send()) {
            _flush_send_queue( $dbus, $reactor, $socket );
        }
    };
}

sub DESTROY {
    my ($self) = @_;

    if (my $socket = delete $self->{'socket'}) {
        Mojo::IOLoop->singleton->reactor()->remove($socket);
    }

    $self->SUPER::DESTROY() if $ISA[0]->can('DESTROY');

    return;
}

1;
