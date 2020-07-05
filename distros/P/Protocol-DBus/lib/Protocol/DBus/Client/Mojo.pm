package Protocol::DBus::Client::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::Mojo - D-Bus with L<Mojolicious>

=head1 SYNOPSIS

    use experimental 'signatures';

    my $dbus = Protocol::DBus::Client::Mojo::system();

    $dbus->initialize_p()->then(
        sub ($msgr) {
            my $a = $msgr->send_call_p( .. )->then( sub ($resp) {
                # ..
            } );

            my $b = $msgr->send_call_p( .. )->then( sub ($resp) {
                # ..
            } );

            return Mojo::Promise->all( $a, $b );
        },
    )->wait();

=head1 DESCRIPTION

This module provides an interface between L<Mojo::IOLoop> and
L<Protocol::DBus::Client>. It subclasses L<Protocol::DBus::Client::EventBase>.

L<Mojolicious>-based applications can use this module to interface easily
with D-Bus.

=head1 INTERFACE NOTES

This module exposes mostly the same interface as
L<Protocol::DBus::Client::AnyEvent>, except for a bit of
“Mojo-specific” behavior:

=over

=item * Returned promises, both from C<initialize()> and
the messenger object’s C<send_call()>, are instances of L<Mojo::Promise>
rather than L<Promise::ES6>.

=item * C<initialize_p()> and C<send_call_p()> exist as aliases for
C<initialize()> and C<send_call()>, respectively.

=back

=cut

#----------------------------------------------------------------------

our @ISA;

use parent qw( Protocol::DBus::Client::EventBase );

use Mojo::IOLoop ();

use constant _PROMISE_CLASS => 'Mojo::Promise';

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

sub initialize {
    return _to_mojo( shift()->SUPER::initialize(@_) );
}

*initialize_p = *initialize;

sub _to_mojo {
    my ($p_es6) = @_;

    return Mojo::Promise->new( sub { $p_es6->then(@_) } )->then( sub {
        return bless $_[0], 'Protocol::DBus::Client::Mojo::Messenger';
    } );
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
                _flush_send_queue($dbus, $reactor, $socket);
            }
            else {
                $read_cb->();
            }
        },
    );

    $self->_resume();

    $self->{'_stop_reading_cr'} = sub {
        Mojo::IOLoop->singleton->reactor()->remove($socket);
    };

    return sub {
        if ($dbus->pending_send()) {
            _flush_send_queue( $dbus, $reactor, $socket );
        }
    };
}

sub _pause {
    Mojo::IOLoop->singleton->reactor()->watch(
        $_[0]{'socket'},
        0,
        $_[0]{'db'}->pending_send(),
    );
}

sub _resume {
    Mojo::IOLoop->singleton->reactor()->watch(
        $_[0]{'socket'},
        1,
        $_[0]{'db'}->pending_send(),
    );
}

sub DESTROY {
    my ($self) = @_;

    if (my $socket = delete $self->{'socket'}) {
        Mojo::IOLoop->singleton->reactor()->remove($socket);
    }

    $self->SUPER::DESTROY() if $ISA[0]->can('DESTROY');

    return;
}

#----------------------------------------------------------------------

package Protocol::DBus::Client::Mojo::Messenger;

use parent 'Protocol::DBus::Client::EventMessenger';

sub send_call {
    my $p = $_[0]->SUPER::send_call( @_[ 1 .. $#_ ] );

    return Mojo::Promise->new( sub { $p->then(@_) } );
}

*send_call_p = *send_call;

1;
