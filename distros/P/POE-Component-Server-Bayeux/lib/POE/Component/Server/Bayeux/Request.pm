package POE::Component::Server::Bayeux::Request;

=head1 NAME

POE::Component::Server::Bayeux::Request - A single Bayeux request

=head1 DESCRIPTION

Objects in this class represent a single Bayeux request made to a Bayeux server.  Requests are instantiated with an HTTP::Request and HTTP::Response object.  This class is responsible for parsing the request content into a JSON object, creating one or more L<POE::Component::Server::Bayeux::Message> objects that represent the possible message types of the Bayeux protocol, and handling each one in turn.

=cut

use strict;
use warnings;
use HTTP::Status; # for RC_OK
use HTTP::Request::Common;
use CGI::Simple::Util qw(unescape);
use JSON::Any qw(XS);
use Data::UUID;
use Params::Validate;

use POE qw(Component::Server::Bayeux::Message::Factory);

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(
    id
    is_complete
    is_error
    ip
    http_request
    http_response
    json_response
    messages
    responses
    heap
    delay
    post_handle
    json_comment_filtered
));

## Class Globals ###

my $json = JSON::Any->new();
my $uuid = Data::UUID->new();

## Class Methods ###

=head1 CLASS METHODS

=head2 new ()

=over 4

Requires 'request' (L<POE::Component::Server::HTTP::Request>), 'response' (L<POE::Component::Server::HTTP::Response>), and 'server_heap'.
Returns init()'ed class object.

=back

=cut

sub new {
    my $class = shift;

    my %args = validate(@_, {
        request => 1,
        response => 1,
        server_heap => 1,
        ip => 0,
    });

    my %self = (
        http_request => $args{request},
        http_response => $args{response},
        heap => $args{server_heap},
        messages => [],
        responses => [],
        id => $uuid->create_str,
        ip => $args{ip},
    );

    my $self = bless \%self, $class;
    $self->init();
    return $self;
}

## Object Methods, Public ###

=head1 OBJECT METHODS

=head2 handle ()

=over 4

Call after creating the request.  Calls the pre_handle(), handle()
methods on each message, possibly completing the request.

=back

=cut

sub handle {
    my ($self) = @_;

    my $heap = $self->heap;

    # Some messages (/meta/connect, for example) need to be handled in a specific
    # order.  Allow each message to affect the queueing.
    foreach my $message (@{ $self->messages }) {
        $message->pre_handle();
    }

    # Starting at the beginning of the message array, process each message in
    # turn.  Messages will interact with the Request $self object, adding responses
    # and in some cases affecting other messages still in the stack.

    while (my $message = shift @{ $self->messages }) {
        $message->handle();
    }

    if ($self->delay) {
        $poe_kernel->post($heap->{manager}, 'delay_request', $self->id, $self->delay);
        $self->delay(0);
        $self->is_complete(0);
        $self->http_response->streaming(1);
    }
    else {
        $self->complete();
    }
}

=head2 complete ()

=over 4

Completes the request, calling the post_handle() method on the messages
that need it.

=back

=cut

sub complete {
    my ($self) = @_;

    $self->form_response( @{ $self->responses } );
    $self->is_complete(1);
    if ($self->http_response->streaming) {
        $self->http_response->send( $self->http_response );
        $self->http_response->close();
    }

    # Ensure no KeepAlive
    $self->http_request->header(Connection => 'close');

    if ($self->post_handle) {
        while (my $message = shift @{ $self->post_handle }) {
            $message->post_handle();
        }
    }
}

## Object Methods, Private ###

=head1 PRIVATE METHODS

=over 4

These methods are mainly called by messages during their handle() phase.

=back

=head2 client ($id)

=over 4

Returns a L<POE::Component::Server::Bayeux::Client> object with the given id.

=back

=cut

sub client {
    my ($self, $id) = @_;

    return POE::Component::Server::Bayeux::Client->new(
        request => $self,
        id => $id,
        server_heap => $self->heap,
    );
}

=head2 add_response ($response)

=over 4

Adds a message response onto the stack of responses.

=back

=cut

sub add_response {
    my ($self, $response) = @_;

    push @{ $self->responses }, $response;
}

=head2 clear_stack ()

=over 4

Clears all messages and responses.

=back

=cut

sub clear_stack {
    my ($self) = @_;

    $self->messages([]);
    $self->responses([]);
}

=head2 add_post_handle ($message)

=over 4

Adds a message to be handled in the post_handle() code.

=back

=cut

sub add_post_handle {
    my ($self, $message) = @_;

    push @{ $self->{post_handle} }, $message;
}

=head2 init ()

=over 4

Parses the L<POE::Component::Server::HTTP::Request> object, extracting the JSON
payload, creating a stack of L<POE::Component::Server::Bayeux::Message> messages.

=back

=cut

sub init {
    my ($self) = @_;

    my $request = $self->{http_request};
    my $response = $self->{http_response};

    ## Extract the JSON payload

    my $params;
    my $json_requests = [];

    my $payload;

    # Parse the content type string

    my $content_type = $request->content_type;

    # Support 'text/json; charset=UTF-8'
    my %content_type_opts;
    my @content_type_parts = split /\s*;\s*/, $content_type;
    if (int @content_type_parts > 1) {
        $content_type = shift @content_type_parts;
        foreach my $part (@content_type_parts) {
            my ($key, $value) = split /=/, $part;
            # May or may not be key/value pairs, and are case-sensitive
            $content_type_opts{$key} = $value;
        }
    }

    if ($content_type eq 'application/x-www-form-urlencoded') {
        # POST or GET
        if (my $content = $request->content) {
            $params = $content;
        }
        elsif ($request->uri =~ m!\?message=!) {
            ($params) = $request->uri =~ m/\?(.*)/;
        }

        if (! $params) {
            return $self->error("No content found in HTTP request (content type '$content_type')");
        }

        # Decode the urlencoded key-value pairs
        my %content;
        foreach my $pair (split /&/, $params) {
            my ($key, $value) = split /=/, $pair, 2;
            next unless $key && $value;
            $content{ unescape($key) } = unescape($value);
        }

        if (! $content{message}) {
            return $self->error("No 'message' key pair found in content");
        }
        $payload = $content{message};
    }
    elsif ($content_type eq 'text/json') {
        $payload = $request->content;
    }
    else {
        return $self->error("Unsupported connection content-type '$content_type'");
    }

    # Decode the payload
    eval {
        $json_requests = $json->decode($payload);
    };
    if ($@) {
        return $self->error("Failed to decode JSON payload: $@" );
    }
    if (! $json_requests || ! ref $json_requests) {
        return $self->error("Invalid JSON payload; must be array or object");
    }
    if (ref $json_requests eq 'HASH') {
        $json_requests = [ $json_requests ];
    }

    $self->logger->debug("New remote request from ".$self->ip.", id ".$self->id.":", $json_requests);

    foreach my $message (@$json_requests) {
        my $bayeux_message;
        eval {
            $bayeux_message = POE::Component::Server::Bayeux::Message::Factory->create(
                request => $self,
                data => $message,
            );
        };
        if ($@ || ! $bayeux_message
            || $bayeux_message->isa('POE::Component::Server::Bayeux::Message::Invalid')
        ) {
            $self->error("Invalid message found" . ($@ ? " ($@)" : ''));
            $self->logger->debug("Remote request was invalid");
            last;
        }
        else {
            push @{ $self->{messages} }, $bayeux_message;
        }
    }
}

=head2 error ($message)

=over 4

Convienence method to throw an error, returning to the client.

=back

=cut

sub error {
    my ($self, $error) = @_;

    return if $self->is_error;

    $self->form_response(
        {
            error => $error,
            successful => JSON::XS::false,
        }
    );

    $self->is_error(1);
    $self->is_complete(1);
}

=head2 form_response (@messages)

=over 4

Encodes the messages into the payload of the response

=back

=cut

sub form_response {
    my ($self, @message) = @_;

    my $response = $self->http_response;
    $self->json_response( \@message );
    my $encoded = $json->encode( \@message );

    my $type = 'text/json';
    if ($self->json_comment_filtered) {
        $encoded = "/*$encoded*/";
        $type = 'text/json-comment-filtered';
    }

    $response->header( 'Content-Type' => "$type; charset=utf-8" );
    $response->code(RC_OK);
    $response->content( $encoded );
}

=head2 logger ()

=over 4

Returns the server's logger.

=back

=cut

sub logger {
    my ($self) = @_;

    return $self->heap->{logger};
}

## POE passthru methods

=head2 subscribe ($client_id, $channel)

=over 4

Passthru to the POE server's subscribe state

=back

=cut

sub subscribe {
    my ($self, $client_id, $channel) = @_;
    $poe_kernel->post($self->heap->{manager}, 'subscribe', {
        client_id => $client_id,
        channel => $channel,
    });
}

=head2 unsubscribe ($client_id, $channel)

=over 4

Passthru to the POE server's unsubscribe state

=back

=cut

sub unsubscribe {
    my ($self, $client_id, $channel) = @_;
    $poe_kernel->post($self->heap->{manager}, 'unsubscribe', {
        client_id => $client_id,
        channel => $channel,
    });
}

=head2 publish ($client_id, $channel, $data)

=over 4

Passthru to the POE server's publish state

=back

=cut

sub publish {
    my ($self, $client_id, $channel, $data) = @_;
    $poe_kernel->post($self->heap->{manager}, 'publish', {
        client_id => $client_id,
        channel => $channel,
        data => $data,
    });
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
