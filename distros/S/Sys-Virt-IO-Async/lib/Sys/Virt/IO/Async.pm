package Sys::Virt::IO::Async;

use strict;
use warnings;

use parent 'IO::Async::Notifier';

use Feature::Compat::Try;

use Scalar::Util 'reftype';
use Symbol 'qualify_to_ref';

our $VERSION = '0.0.5';


sub _make_close_cb {
    my ($self) = @_;
    my $on_close = $self->{on_close} // sub {};
    if (reftype $on_close ne 'CODE') {
        # If it's not a coderef, it must be a future
        $on_close = sub {
            $self->loop->later(sub { $on_close->done(); });
        };
    }
    return $self->_capture_weakself(
        sub {
            my ($self, @args) = @_;

            $on_close->($self, @args);
            $self->deregister_callbacks;
            $self->remove_from_parent;
        });
}

sub _queued_cb {
    my ( $cb, $cancel ) = @_;
    if (reftype $cb ne 'CODE') {
        # assume it's a Future::Queue
        return sub {
            my ($self, @args) = @_;
            $self->loop->later(
                sub {
                    try {
                        # push generates an exception when the que finished
                        $cb->push( [ $self, @args ] );
                    }
                    catch ($e) {
                        $cancel->( $self );
                    }
                });
        };
    }
    return $cb;
}

sub configure {
    my ($self, %args) = @_;

    $self->{_cb} = {
        domain  => {},
        network => {},
        pool    => {},
        device  => {},
        secret  => {}
    };
    $self->{virt} = delete $args{virt}
        or die 'Missing required "virt" argument';

    $self->{on_close} = delete $args{on_close};
    $self->{virt}->register_close_callback( $self->_make_close_cb );

    $self->{on_domain_change} = delete $args{on_domain_change};
    if (my $on_domain_change = $self->{on_domain_change}) {
        my $cancel = sub {
            my $self = shift;
            $self->{virt}->domain_event_deregister();
        };
        $self->{virt}->domain_event_register(
            $self->_replace_weakself(
                _queued_cb( $on_domain_change, $cancel )
            ));
    }

    $self->SUPER::configure(%args);
}

sub deregister_callbacks {
    my ($self) = @_;
    for my $type (keys $self->{_cb}->%*) {
        for my $cb_id (keys $self->{_cb}->{$type}->%*) {
            $self->domain_deregister_any( $cb_id );
        }
    }
}

sub domain_event_register {
    die 'A domain event callback can only be added at Sys::Virt::IO::Async instantiation';
}

sub domain_event_deregister {
    die 'Domain event callback deregistration not supported';
}

sub _adopt_cb {
    my ($self, $type, $cb_id) = @_;
    $self->{_cb}->{$type}->{$cb_id} = 1;
    return $cb_id;
}

sub domain_event_register_any {
    my ($self, $dom, $event, $cb) = @_;

    my $cb_id;
    my $cancel = sub {
        my $self = shift;
        $self->domain_event_deregister_any( $cb_id );
    };
    return $cb_id = $self->_adopt_cb(
        'domain',
        $self->{virt}->domain_event_register_any(
            $dom,
            $event,
            $self->_replace_weakself( _queued_cb( $cb, $cancel ) )
        ));
}

sub domain_event_deregister_any {
    my ($self, $cb_id) = @_;
    $self->{virt}->domain_event_deregister_any( $cb_id );
    delete $self->{_cb}->{domain}->{$cb_id};
}

sub network_event_register_any {
    my ($self, $net, $event, $cb) = @_;

    my $cb_id;
    my $cancel = sub {
        my $self = shift;
        $self->network_event_deregister_any( $cb_id );
    };
    return $cb_id = $self->_adopt_cb(
        'network',
        $self->{virt}->network_event_register_any(
            $net,
            $event,
            $self->_replace_weakself( _queued_cb( $cb, $cancel ) )
        ));
}

sub network_event_deregister_any {
    my ($self, $cb_id) = @_;
    $self->{virt}->network_event_deregister_any( $cb_id );
    delete $self->{_cb}->{network}->{$cb_id};
}

sub storage_pool_event_register_any {
    my ($self, $pool, $event, $cb) = @_;

    my $cb_id;
    my $cancel = sub {
        my $self = shift;
        $self->storage_pool_event_deregister_any( $cb_id );
    };
    return $cb_id = $self->_adopt_cb(
        'pool',
        $self->{virt}->storage_pool_event_register_any(
            $pool,
            $event,
            $self->_replace_weakself( _queued_cb( $cb, $cancel ) )
        ));
}

sub storage_pool_event_deregister_any {
    my ($self, $cb_id) = @_;
    $self->{virt}->storage_pool_event_deregister_any( $cb_id );
    delete $self->{_cb}->{pool}->{$cb_id};
}

sub node_device_event_register_any {
    my ($self, $dev, $event, $cb) = @_;

    my $cb_id;
    my $cancel = sub {
        my $self = shift;
        $self->node_device_event_deregister_any( $cb_id );
    };
    return $cb_id = $self->_adopt_cb(
        'device',
        $self->{virt}->node_device_event_register_any(
            $dev,
            $event,
            $self->_replace_weakself( _queued_cb( $cb, $cancel ) )
        ));
}

sub node_device_event_deregister_any {
    my ($self, $cb_id) = @_;
    $self->{virt}->node_device_event_deregister_any( $cb_id );
    delete $self->{_cb}->{device}->{$cb_id};
}

sub secret_event_register_any {
    my ($self, $secret, $event, $cb) = @_;

    my $cb_id;
    my $cancel = sub {
        my $self = shift;
        $self->secret_event_deregister_any( $cb_id );
    };
    return $cb_id = $self->_adopt_cb(
        'secret',
        $self->{virt}->secret_event_register_any(
            $secret,
            $event,
            $self->_replace_weakself( _queued_cb( $cb, $cancel ) )
        ));
}

sub secret_event_deregister_any {
    my ($self, $cb_id) = @_;
    $self->{virt}->secret_event_deregister_any( $cb_id );
    delete $self->{_cb}->{secret}->{$cb_id};
}

# Using the autoloader mechanism eliminates the need to keep
# this package up to date with every Sys::Virt release while
# still completely mirrorring the API provided by it.

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, @args) = @_;
    my $func = $AUTOLOAD;
    $func =~ s/.*:://;
    {
        my $ref = qualify_to_ref $func;
        *$ref = sub {
            my ($s, @a) = @_;
            return $s->{virt}->$func( @a );
        };

        goto &$func;
    }
}

1;

__END__

=head1 NAME

Sys::Virt::IO::Async - Helpers to integrate Sys::Virt with IO::Async

=head1 SYNOPSIS

  use IO::Async::Loop;
  use Sys::Virt;
  use Sys::Virt::Event;
  use Sys::Virt::IO::Async;
  use Sys::Virt::IO::Async::EventImpl;

  my $impl = Sys::Virt::IO::Async::EventImpl->new;
  my $loop = IO::Async::Loop->new;
  $loop->add( $impl );

  my $conn = Sys::Virt::IO::Async->new(
    virt => Sys::Virt->new( uri => 'qemu:///system' ),
    on_close => sub { ... },
    on_domain_change => sub { ... });

  $impl->add_child( $conn );


  # ... do stuff ...

  # close the connection:
  undef $conn;

=head1 DESCRIPTION

This module is a notifier for L<Sys::Virt>.  It makes most sense to use this
module in conjunction with an event loop (See L<Sys::Virt::Event> and
L<Sys::Virt::EventImpl>).  It invokes the C<on_close> event callback when the
connection to C<libvirt> is lost.  While connected, any domain life cycle
events trigger the C<on_domain_change> event callback.

In addition to triggering these event callbacks, it also tracks callbacks
registered with these functions in C<Sys::Virt>: C<domain_event_register_any>,
C<network_event_register_any>, C<storage_pool_event_register_any>,
C<node_device_event_register_any> and C<secret_event_register_any>.  The
tracked callbacks (including C<on_close> and C<on_domain_change>) are
unregistered when the C<close> event occurs: these callbacks must be
deallocated for the C<Sys::Virt> instance to be garbage collected.

=head1 METHODS

=head2 new( virt => $virt, on_close => $close, on_domain_change => $change)

Constructor.  Returns a C<Sys::Virt::IO::Async> instance.

The C<$on_close> argument is either a coderef to be executed when the
connection closes, or a future which will be resolved after the callback
completes.

The C<$change> argument is either a coderef to be executed when a domain
life cycle event occurs, or a L<Future::Queue> instance which will have
the callback arguments pushed after the callback completes.

The C<$virt> argument is required.

=head2 configure

Overrides the method inherited from L<IO::Async::Notifier>.

=head2 deregister_callbacks

Deregisters all callbacks being tracked, which were registered using
C<domain_event_register_any>, C<network_event_register_any>,
C<storage_pool_event_register_any>, C<node_device_event_register_any> or
C<secret_event_register_any> and not yet deregistered using the associated
deregistration functions.

=head2 domain_event_register

=head2 domain_event_deregister

Unsupported: domain event callback registration handled at instantiation.

=head2 domain_event_register_any($dom, $eventID, $callback)

=head2 network_event_register_any($net, $eventID, $callback)

=head2 storage_pool_event_register_any($pool, $eventID, $callback)

=head2 node_device_event_register_any($dev, $eventID, $callback)

=head2 secret_event_register_any($secret, $eventID, $callback)

Registers the callback with the wrapped C<Sys::Virt> instance; C<$callback>
is called with a C<Sys::Virt::IO::Async> instance as its first argument
instead of the C<Sys::Virt> instance if the callback had been registered
through it directly.

If the C<$callback> is an instance of L<Future::Queue>, the arguments are
pushed onto the queue as an array reference after the callback completes.
The callback can be deregistered by calling the C<finish> method of the
queue.

B<IMPORTANT> Code which tries to modify the state of libvirt (domains,
networks, etc., but I<also> callbacks) should be executed outside of the
callback.  This can be achieved using C<$conn->loop->later()>.

The registered callback is tracked and deregistered automatically when the
connection with C<libvirt> is closed,

Returns a C<$callbackID> to be used for explicit deregistration.

=head2 domain_event_deregister_any($callbackID)

=head2 network_event_deregister_any($callbackID)

=head2 storage_pool_event_deregister_any($callbackID)

=head2 node_device_event_deregister_any($callbackID)

=head2 secret_event_deregister_any($callbackID)

Deregisters the callback, preventing further calls; stops tracking the
callback for deregistration on connection close.

=head1 METHOD CALL FORWARDING

All method invocations for methods not documented above, are forwarded
to the wrapped C<Sys::Virt> instance:

  # this:
  my $uri = $conn->get_uri();

  # is similar to this:
  my $uri = $conn->virt->get_uri();

This way the instance of this class is a drop-in replacement for a
C<Sys::Virt> instance with a few minor exceptions (the methods documented
above).

=head1 AUTHORS

=over 4

=item * Erik Huelsmann C<< ehuels@gmail.com >>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Erik Huelsmann.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.
