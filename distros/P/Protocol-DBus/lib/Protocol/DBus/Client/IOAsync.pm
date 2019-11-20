package Protocol::DBus::Client::IOAsync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::IOAsync - D-Bus with L<IO::Async>

=head1 SYNOPSIS

The following creates a D-Bus connection, sends two messages,
waits for their responses, then ends:

    use experimental 'signatures';

    my $loop = IO::Async::Loop->new();

    my $dbus = Protocol::DBus::Client::IOAsync::system($loop)

    $dbus->initialize()->then(
        sub ($dbus) {
            my $a = $dbus->send_call( .. )->then( sub ($resp) {
                # ..
            } );

            my $b = $dbus->send_call( .. )->then( sub ($resp) {
                # ..
            } );

            return Promise::ES6->all( [$a, $b] );
        },
    )->finally( sub { $loop->stop() } );

    $loop->run();

=head1 DESCRIPTION

This module provides an L<IO::Async> interface on top of
L<Protocol::DBus::Client>. It subclasses L<Protocol::DBus::Client::EventBase>.

=cut

our @ISA;   # checked explicitly in DESTROY

use parent qw( Protocol::DBus::Client::EventBase );

use IO::Async::Handle ();

#----------------------------------------------------------------------

=head1 STATIC FUNCTIONS

This module offers C<system()> and C<login_session()> functions that
offer similar functionality to their analogues in
L<Protocol::DBus::Client>, but they return instances of this class.

Additionally, both functions require an L<IO::Async::Loop> to be passed.

=cut

sub system {
    return __PACKAGE__->_create_system( $_[0] );
}

sub login_session {
    return __PACKAGE__->_create_login_session( $_[0] );
}

#----------------------------------------------------------------------

sub _create {
    my ($class, $dbus, $loop) = @_;

    die 'need loop!' if !$loop;

    open my $s, '+>&=' . $dbus->fileno() or die "failed to dupe filehandle: $!";

    return $class->SUPER::_create($dbus, loop => $loop, socket => $s);
}

sub _initialize {
    my ($self, $y, $n) = @_;

    my $dbus = $self->{'db'};
    my $loop = $self->{'loop'};
    my $s = $self->{'socket'};

    my $watch;
    my $watch_sr = \$watch;

    my $each_time = sub {
        $$watch_sr->want_writeready(0);

        $n->($@) if !eval {
            if ( $dbus->initialize() ) {
                $loop->remove($$watch_sr);
                $$watch_sr = undef;
                $y->();
            }
            else {
                $$watch_sr->want_writeready( $dbus->init_pending_send() );
            }

            1;
        };
    };

    $watch = IO::Async::Handle->new(
        handle => $s,

        on_read_ready => $each_time,
        on_write_ready => $each_time,
    );

    $loop->add($watch);

    $each_time->();
}

sub _set_watches_and_create_messenger {
    my ($self) = @_;

    my $dbus = $self->{'db'};
    my $socket = $self->{'socket'};

    my $watch_sr;

    my $watch = IO::Async::Handle->new(
        handle => $socket,

        on_read_ready => $self->_create_get_message_callback(),

        on_write_ready => sub {
            $$watch_sr->want_writeready(0) if $dbus->flush_write_queue();
        },
    );

    $self->{'loop'}->add($watch);

    $self->{'watch_sr'} = $watch_sr = \$watch;

    return sub {
        $watch->want_writeready( $dbus->pending_send() );
    };
}

sub DESTROY {
    if (my $watch_sr = delete $_[0]{'watch_sr'}) {
        $_[0]{'loop'}->remove($$watch_sr);
        $$watch_sr = undef;
    }

    $_[0]->SUPER::DESTROY() if $ISA[0]->can('DESTROY');

    return;
}

1;
