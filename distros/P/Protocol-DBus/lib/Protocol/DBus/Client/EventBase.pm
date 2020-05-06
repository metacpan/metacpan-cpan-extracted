package Protocol::DBus::Client::EventBase;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::EventBase - Base class for event-driven L<Protocol::DBus>

=head1 DESCRIPTION

This base class encapsulates the fundamentals of an event-loop-aware
L<Protocol::DBus::Client>. If you use D-Bus in a standard event loop
(i.e., an event loop from CPAN), you probably want to use a subclass of
this module.

The module you’ll actually use will be an end class like
L<Protocol::DBus::Client::IOAsync> or
L<Protocol::DBus::Client::AnyEvent>.

=head1 SUBCLASS INTERFACE

Currently the subclass interface is not documented for public consumption.
Contact me if you’d like to change that (and are willing to put in some
effort toward such end).

=head1 TODO

There aren’t tests written against this module or its subclasses.
It would be great to rectify that.

=cut

#----------------------------------------------------------------------

use Protocol::DBus::Client ();
use Protocol::DBus::Client::EventMessenger ();

#----------------------------------------------------------------------

=head1 INSTANCE METHODS

=head2 $promise = I<OBJ>->initialize()

Returns a promise (L<Promise::ES6> instance) that resolves to a
L<Protocol::DBus::Client::EventMessenger> instance. That object, not
this one, is what you’ll use to send and receive messages.

=cut

sub initialize {
    my ($self) = @_;

    return $self->{'_initialize_promise'} ||= $self->{'db'}->_get_promise_class()->new( sub {
        $self->_initialize(@_);
    } )->then( sub {
        my $post_send_cr = $self->_set_watches_and_create_messenger();

        return Protocol::DBus::Client::EventMessenger->new(
            $self->{'db'},
            $post_send_cr,
        );
    } );
}

=head2 $obj = I<OBJ>->on_signal( $HANDLER_CR )

Installs a handler for D-Bus signals. Whenever I<OBJ> receives such a
message, an instance of L<Protocol::DBus::Message> that represents the
message will be passed to $HANDLER_CR.

Pass undef to disable a previously-set handler.

Returns I<OBJ>.

=cut

sub on_signal {
    my ($self, $cb) = @_;

    $self->{'_on_signal_r'} = \$cb;

    return $self;
}

=head2 $obj = I<OBJ>->on_message( $HANDLER_CR )

Like C<on_signal()> but for all received D-Bus messages, not just signals.
This is useful for monitoring … and not much else?

=cut

sub on_message {
    my ($self, $cb) = @_;

    $self->{'_on_message_r'} = \$cb;

    return $self;
}

=head2 $obj = I<OBJ>->on_failure( $HANDLER_CR )

Set this to receive a copy of whatever error kills the connection.
If not set, such an error will be warn()ed.

=cut

sub on_failure {
    my ($self, $cb) = @_;

    $self->{'_on_failure'} = $cb;

    return $self;
}

#----------------------------------------------------------------------

sub _on_failure {
    my ($self, $cb) = @_;

    $self->{'_on_failure'} = $cb;

    return $self;
}

sub _create_system {
    return $_[0]->_create(
        Protocol::DBus::Client::system(),
        @_[ 1 .. $#_ ],
    );
}

sub _create_login_session {
    return $_[0]->_create(
        Protocol::DBus::Client::login_session(),
        @_[ 1 .. $#_ ],
    );
}

sub _create {

    my ($class, $dbus, %opts) = @_;

    $opts{'db'} = $dbus;

    $dbus->blocking(0);

    return bless \%opts, $class;
}

sub _create_get_message_callback {
    my ($self) = @_;

    my $dbus = $self->{'db'};

    my $on_message_cr_r = $self->{'_on_message_r'} ||= \do { my $v = undef };
    my $on_signal_cr_r = $self->{'_on_signal_r'} ||= \do { my $v = undef };

    my $on_failure_cr_r = \$self->{'_on_failure'};
    my $stop_reading_cr_r = \$self->{'_stop_reading_cr'};

    return sub {
        my $ok = eval {
            while (my $msg = $dbus->get_message()) {
                if ($$on_message_cr_r) {
                    $$on_message_cr_r->($msg);
                }

                if ($$on_signal_cr_r && $msg->type_is('SIGNAL')) {
                    $$on_signal_cr_r->($msg);
                }
            }

            1;
        };

        if (!$ok) {
            my $err = $@;

            if (my $cr = $$on_failure_cr_r) {
                $cr->($err);
            }
            else {
                warn $err;
            }

            $$stop_reading_cr_r->();
        }
    };
}

sub DESTROY {
    if (defined ${^GLOBAL_PHASE} && 'DESTROY' eq ${^GLOBAL_PHASE}) {
        warn "$_[0] lasted until ${^GLOBAL_PHASE} phase!";
    }
}

1;
