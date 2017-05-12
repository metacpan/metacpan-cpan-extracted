package POE::Component::Server::Bayeux::Client;

=head1 NAME

POE::Component::Server::Bayeux::Client - An object representing a single client of the server

=head1 DESCRIPTION

Used internally by L<POE::Component::Server::Bayeux>.

=cut

use strict;
use warnings;
use Params::Validate;
use Data::UUID;
use POE;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(
    request id ip
    is_error
    flags
    server_heap
    heap
    session
));

my $uuid = Data::UUID->new();

=head1 USAGE

=head2 new (...)

=over 4

Arguments:

=over 4

=item I<server_heap> (required)

The server's heap object

=item I<request>

A L<POE::Component::Server::Bayeux::Request> object representing an HTTP-connected client.

=item I<id>

The clientId.  If not given, generates one using L<Data::UUID>.

=item I<session>

For locally connected clients, the POE session alias or ID to post back to.

=back

=back

=cut

sub new {
    my $class = shift;

    my %self = validate(@_, {
        server_heap => 1,
        request => 0,
        id => 0,
        session => 0,

        flags => { default => {} },
        heap  => { default => {} },
    });
    my $self = bless \%self, $class;

    if ($self->request) {
        $self->ip( $self->request->ip );
    }

    # Don't let the client id be arbitrarily defined save by a POE session
    if ($self->id && ! $self->session && ! $self->server_heap->{clients}{$self->id}) {
        $self->is_error("Client id '".$self->id."' is invalid");
        return $self;
    }

    if (! $self->id || ($self->session && ! $self->server_heap->{clients}{$self->id})) {
        # Create a new client id
        $self->id( $uuid->create_str() ) unless $self->id();
        my $heap = {
            created => time,
            ip => $self->ip,
            flags => {
                last_connect => time,
            },
            session => $self->session,
        };
        $self->server_heap->{clients}{ $self->id } = $heap;

        # Let the manager server know so it can do notifications
        $poe_kernel->post( $self->server_heap->{manager},
            'client_connect', {
                client_id => $self->id,
                ($self->session ? (
                    session => $self->session,
                ) : (
                    ip => $self->ip,
                )),
            },
        );
    }

    $self->heap( $self->server_heap->{clients}{$self->id} );
    $self->session( $self->heap->{session} ) if ! $self->session && $self->heap->{session};
    $self->flags( $self->heap->{flags} );

    # Special: if is_polling, make sure it's still a pending request
    if (my $req_id = $self->heap->{flags}{is_polling}) {
        delete $self->heap->{flags}{is_polling}
            if ! defined $self->server_heap->{requests}{$req_id};
    }

    return $self;
}

=head1 METHODS

=head2 disconnect ()

=head2 complete_poll ()

=over 4

Completes an active poll if there is one

=back

=cut

sub disconnect {
    my ($self) = @_;

    $self->complete_poll();

    # Let the manager server know so it can do notifications and unsubscribes
    $poe_kernel->post( $self->server_heap->{manager},
        'client_disconnect', { client_id => $self->id });
}

sub complete_poll {
    my ($self) = @_;
    if (my $req_id = $self->flags->{is_polling}) {
        $poe_kernel->post( $self->server_heap->{manager},
            'complete_request', $req_id );
    }
}

=head2 message_acl ($message)

=over 4

Called with a L<POE::Component::Server::Bayeux::Message>, the client is to evaluate
wether the message is invalid within the context of the client - as in, perform an
authorization check.  If there's an error, the message will have it's is_error() field
set with the error.

=back

=cut

sub message_acl {
    my ($self, $message) = @_;

    # If the client has asked for comment filtered JSON, pass this along to the
    # request which will be encapsulating the results.
    if ($self->flags->{'json-comment-filtered'}) {
        $message->request->json_comment_filtered(1);
    }

    # All messages fail if I'm in error
    if ($self->is_error) {
        $message->is_error($self->is_error);
        return;
    }

    $self->server_config->{MessageACL}->($self, $message);
    return if $message->is_error;
}

=head2 is_subscribed ($channel)

=over 4

Returns boolean of wether the client is subscribed to the literal channel provided

=back

=cut

sub is_subscribed {
    my ($self, $channel) = @_;

    return exists $self->heap->{subscriptions}{$channel};
}

=head2 send_message ($message, $subscription_args)

=over 4

Sends, or queues, the message to the client.  $subscription_args is the same hashref that
was passed to the server's subscribe() method when this client subscribed to the channel.
Structure of the message is same as Bayeux '5.2. Deliver Event message'.

=back

=cut

sub send_message {
    my ($self, $message, $subscription_args) = @_;

    if ($subscription_args->{no_callback}) {
        return;
    }

    if ($self->session) {
        my $state = $subscription_args->{state} || 'deliver';
        $poe_kernel->post( $self->session, $state, $message );
        return;
    }

    $self->check_timeout();
    if ($self->is_error()) {
        $self->logger->error("Not sending message to client ".$self->id.": ".$self->is_error);
        return;
    }

    $self->logger->debug("Queuing message to client ".$self->id);
    push @{ $self->heap->{queued_responses} }, $message;

    # Delay flush_queue so that if other responses need to be queued, they'll go out at the same time
    $poe_kernel->post($self->server_heap->{manager}, 'delay_sub', 'flush_queue.' . $self->id, 0, sub { $self->flush_queue });
}

=head2 check_timeout ()

=over 4

Checks last time HTTP-connected client performed connected, and removes client if
it's stale (according to server arg ConnectTimeout).

=back

=cut

sub check_timeout {
    my ($self) = @_;

    return if $self->session;
    return if $self->flags->{is_polling};
    my $connect_timeout = $self->server_heap->{args}{ConnectTimeout};
    if (time - $self->flags->{last_connect} < $connect_timeout) {
        return;
    }

    $self->is_error("Connect timeout; removing client");
    $self->disconnect();
}

=head2 flush_queue ()

=over 4

Flush the queue of messages, if there is any, and only if client is currently
connected.  Only used for HTTP-connected clients.

=back

=cut
    
sub flush_queue {
    my ($self) = @_;

    return if ! $self->heap->{queued_responses};
    return if ! $self->flags->{is_polling};

    my $request = $self->server_heap->{requests}{ $self->flags->{is_polling} };
    return if ! $request;

    my $queue = delete $self->heap->{queued_responses};
    return if ! ref $queue || ref $queue ne 'ARRAY' || int @$queue == 0;

    $self->logger->debug("Flushing queue to active request on ".$self->id);

    $request->add_response($_) foreach @$queue;
    $self->complete_poll();
}

=head2 logger ()

=over 4

Return a reference to the servers logger.

=back

=cut

sub logger {
    my ($self) = @_;

    return $self->server_heap->{logger};
}

=head2 server_config ()

=over 4

Returns the server's args

=back

=cut

sub server_config {
    my ($self) = @_;

    return $self->server_heap->{args};
}
=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut

1;
