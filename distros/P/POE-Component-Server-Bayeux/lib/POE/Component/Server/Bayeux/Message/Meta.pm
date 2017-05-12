package POE::Component::Server::Bayeux::Message::Meta;

=head1 NAME

POE::Component::Server::Bayeux::Message::Meta - handles /meta/ channels

=head1 DESCRIPTION

Subclasses L<POE::Component::Server::Bayeux::Message> to implement the /meta/* channels.

=cut

use strict;
use warnings;
use JSON::Any qw(XS);
use Switch;
use Params::Validate qw(:types);
use base qw(POE::Component::Server::Bayeux::Message);

__PACKAGE__->mk_accessors(qw(type));

my %known_types = (
    handshake => {
        version => 1,
        supportedConnectionTypes => { type => ARRAYREF },
        minimumVersion => 0,
    },
    connect => {
        clientId => 1,
        connectionType => 1,
    },
    disconnect => {
        clientId => 1,
    },
    subscribe => {
        clientId => 1,
        subscription => 1,
    },
    unsubscribe => {
        clientId => 1,
        subscription => 1,
    },
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # Extract and save the type of meta message

    my ($type) = $self->channel =~ m{^/meta/(.+)$};
    if (! $type || ! $known_types{$type}) {
        $self->request->error("Invalid channel ".$self->channel);
        return;
    }
    $self->type($type);

    return $self;
}

sub validate_fields {
    my ($self) = @_;

    my %validate_spec = %{ $known_types{ $self->type } };
    $self->SUPER::validate_fields(%validate_spec);
}

sub pre_handle {
    my ($self) = @_;

    return if $self->is_error;

    if ($self->type eq 'connect') {
        # Connect needs to be the only connect message in the stack, and must be first

        my @new_order = ( $self );
        foreach my $message (@{ $self->request->messages }) {
            # Stringify hashref to find self
            next if $message eq $self;

            if ($message->isa(__PACKAGE__) && $message->type eq 'connect') {
                $message->is_error("Can only have on connect message per request");
                next;
            }

            push @new_order, $message;
        }

        $self->request->messages( \@new_order );
    }
}

sub handle {
    my ($self) = @_;

    # Class handle() will call validate_fields()
    $self->SUPER::handle();

    # Message may be in error, but the format of error return is dependent on
    # the type of message we're responding to.

    my @responses;

    switch ($self->type) {
        case 'handshake' {
            # Must ignore any other messages sent in this request
            $self->request->clear_stack();

            my $client;
            if (! $self->is_error) {
                # Get the client by (possibly) generating a new client, passing the extra
                # params in case they contain auth info.
                $client = $self->request->client();

                # Run through acl (may set is_error flag)
                $client->message_acl($self);
            }

            if ($self->is_error) {
                push @responses, {
                    successful => JSON::XS::false,
                    error => $self->is_error,
                };
                last;
            }

            # TODO: Find a common connectionType 
            my $supported_connection_types = $POE::Component::Server::Bayeux::supported_connection_types;

            my %response = (
                version                  => $POE::Component::Server::Bayeux::protocol_version,
                minimumVersion           => $POE::Component::Server::Bayeux::protocol_version,
                supportedConnectionTypes => $supported_connection_types,
                successful               => JSON::XS::true,
                clientId                 => $client->id,
                advice                   => {
                    timeout => 2 * 60 * 1000,
                    interval => 0,
                    reconnect => 'retry',
                },
                ext => {
                    'json-comment-filtered' => JSON::XS::true,
                },
            );

            # Remember client support for json-comment-filtered
            if ($self->ext && $self->ext->{'json-comment-filtered'}) {
                $client->flags->{'json-comment-filtered'} = 1;
            }

            push @responses, \%response;
        }
        case 'connect' {
            my $client;
            if (! $self->is_error) {
                $client = $self->request->client($self->clientId);
                $client->message_acl($self);
                $self->is_error($client->is_error) if $client->is_error;
            }

            if (! $self->error && $client->flags->{is_polling}) {
                $self->is_error("Client ".$self->clientId." is polling already (".$client->flags->{is_polling}.")");
            }

            if ($self->is_error) {
                push @responses, {
                    successful => JSON::XS::false,
                    error      => $self->is_error,
                    clientId   => $self->clientId,
                    advice     => {
                        reconnect => 'handshake',
                    },
                };
                last;
            }

            $client->flags->{is_polling} = $self->request->id;

            push @responses, {
                successful => JSON::XS::true,
                clientId   => $client->id,
                advice     => {
                    timeout => 2 * 60 * 1000,
                    interval => 0,
                    reconnect => 'retry',
                },
            };

            my $no_delay = 0;

            # Handle queued responses
            if (my $queue = delete $client->heap->{queued_responses}) {
                push @responses, @$queue;
                $no_delay = 1;
            }

            # Don't delay the first time they connect
            if (++$client->flags->{connect_times} == 1) {
                $no_delay = 1;
            }
            $client->flags->{last_connect} = time;

            # Come back to me to record last_connect time at end of connect
            $self->request->add_post_handle($self);

            $self->request->delay(120) unless $no_delay;
        }
        case 'disconnect' {
            my $client;
            if (! $self->is_error) {
                $client = $self->request->client($self->clientId);
                $client->message_acl($self);
                $client->disconnect();
            }

            push @responses, {
                successful => $self->is_error ? JSON::XS::false : JSON::XS::true,
                clientId   => $client->id,
                ($self->is_error ? ( error => $self->is_error ) : () ),
            };
        }
        case 'subscribe' {
            my $client;
            if (! $self->is_error) {
                $client = $self->request->client($self->clientId);
                $client->message_acl($self);
            }

            if ($self->is_error) {
                push @responses, {
                    successful => JSON::XS::false,
                    error      => $self->is_error,
                    clientId   => $self->clientId,
                    subscription => $self->subscription,
                };
                last;
            }

            push @responses, {
                successful => JSON::XS::true,
                clientId   => $client->id,
                subscription => $self->subscription,
            };

            # Don't record a subscription to /meta or /service
            if ($self->subscription !~ m{^/(meta|service)/}) {
                $self->request->subscribe($client->id, $self->subscription);
            }
        }
        case 'unsubscribe' {
            my $client;
            if (! $self->is_error) {
                $client = $self->request->client($self->clientId);
                $client->message_acl($self);
            }
            
            if (! $self->is_error && ! $client->is_subscribed($self->subscription)) {
                $self->is_error("Client not subscribed to '" . $self->subscription . "'");
            }

            $self->request->unsubscribe($client->id, $self->subscription);

            push @responses, {
                clientId   => $self->clientId,
                subscription => $self->subscription,
                ($self->is_error ? (
                    successful => JSON::XS::false,
                    error      => $self->is_error,
                ) : (
                    successful => JSON::XS::true,
                ))
            };
        }
    }

    foreach my $response (@responses) {
        $response->{channel} ||= $self->channel;
        $response->{id} = $self->id if $self->id;
        $self->request->add_response($response);
    }
}

sub post_handle {
    my ($self) = @_;

    return unless $self->type eq 'connect';

    my $client = $self->request->client($self->clientId);
    $client->flags->{last_connect} = time;
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
