package Protocol::DBus::Client::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::AnyEvent - D-Bus with L<AnyEvent>

=head1 SYNOPSIS

The following creates a D-Bus connection, sends two messages,
waits for their responses, then ends:

    use experimental 'signatures';

    my $dbus = Protocol::DBus::Client::AnyEvent::system();

    my $cv = AnyEvent->condvar();

    $dbus->initialize()->then(
        sub ($msgr) {
            my $a = $msgr->send_call( .. )->then( sub ($resp) {
                # ..
            } );

            my $b = $msgr->send_call( .. )->then( sub ($resp) {
                # ..
            } );

            return Promise::ES6->all( [$a, $b] );
        },
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This module provides an L<AnyEvent> interface on top of
L<Protocol::DBus::Client>. It subclasses L<Protocol::DBus::Client::EventBase>.

=cut

use parent qw( Protocol::DBus::Client::EventBase );

use AnyEvent ();

#----------------------------------------------------------------------

=head1 STATIC FUNCTIONS

This module provides C<system()> and C<login_session()> functions
that parallel their equivalents in L<Protocol::DBus::Client> but return
an instance of this class instead.

=cut

sub system {
    return __PACKAGE__->_create_system();
}

sub login_session {
    return __PACKAGE__->_create_login_session();
}

#----------------------------------------------------------------------

=head1 SEE ALSO

L<AnyEvent::DBus> is an AnyEvent wrapper for L<Net::DBus>.

=cut

#----------------------------------------------------------------------

sub _initialize {
    my ($self, $y, $n) = @_;

    my $dbus = $self->{'db'};

    my $fileno = $dbus->fileno();

    my $read_watch_r = \do { $self->{'_read_watch'} = undef };
    my $write_watch_r = \do { $self->{'_write_watch'} = undef };

    my $cb_r;

    my $clear_watchers_cr = sub {
        undef $$cb_r;
        undef $$read_watch_r;
        undef $$write_watch_r;
    };

    my $cb = sub {
        my $ok = eval {
            if ( $dbus->initialize() ) {
                $clear_watchers_cr->();
                $y->();
            }

            # It seems unlikely that we’d need a write watch here.
            # But just in case …
            elsif ($dbus->init_pending_send()) {
                $$write_watch_r ||= do {

                    my $current_sub = $$cb_r;

                    AnyEvent->io(
                        fh => $fileno,
                        poll => 'w',
                        cb => $current_sub,
                    );
                };
            }
            else {
                undef $$write_watch_r;
            }

            1;
        };

        if (!$ok) {
            $clear_watchers_cr->();
            $n->($@);
        }
    };

    $cb_r = \$cb;

    $$read_watch_r = AnyEvent->io(
        fh => $fileno,
        poll => 'r',
        cb => $cb,
    );

    $cb->();
}

sub _flush_send_queue {
    my ($dbus, $fileno, $watch_sr) = @_;

    if ($dbus->pending_send()) {
        $$watch_sr = AnyEvent->io(
            fh => $fileno,
            poll => 'w',
            cb => sub { $$watch_sr = undef if $dbus->flush_write_queue() },
        );
    }

    return;
}

sub _set_watches_and_create_messenger {
    my ($self) = @_;

    my $dbus = $self->{'db'};

    my $fileno = $dbus->fileno();

    my $write_watch_sr = \$self->{'_write_watch'};

    my $flush_cr = sub {
        _flush_send_queue( $dbus, $fileno, $write_watch_sr );
    };

    if (!$self->{'_read_watch'}) {

        $flush_cr->();

        $self->{'_read_callback'} = $self->_create_get_message_callback();

        $self->_resume();

        my $read_watch_sr = \$self->{'_read_watch'};

        $self->{'_stop_reading_cr'} = sub {
            $$read_watch_sr = undef;
        };
    }

    return $flush_cr;
}

sub _pause {
    $_[0]->{'_read_watch'} = undef;
}

sub _resume {
    my ($self) = @_;

    $self->{'_read_watch'} ||= AnyEvent->io(
        fh => $self->{'db'}->fileno(),
        poll => 'r',
        cb => $self->{'_read_callback'},
    );
}

1;
