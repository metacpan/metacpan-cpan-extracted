package Mojo::WebSocketProxy::Backend;

use strict;
use warnings;

no indirect;

use Mojo::Util qw(class_to_path);

our $VERSION = '0.16';    ## VERSION

our %CLASSES = ();

=head1 NAME

Mojo::WebSocketProxy::Backend

=head1 DESCRIPTION

Abstract base class for RPC dispatch backends. See
L<Mojo::WebSocketProxy::Backend::JSONRPC> for the original JSON::RPC backend.

=cut

=head1 CLASS METHODS

=cut

=head2 register_type

    $class->register_type($type)

Registers that the invoking subclass implements an RPC backend of the given type.

=cut

sub register_type {
    my ($class, $type) = @_;
    $CLASSES{$type} = $class;
    return;
}

=head2 backend_instance

    $backend = Mojo::WebSocketProxy::Backend->new($type, %args)

Constructs a new instance of the subclass previously registered as handling
the given type. Throws an exception of no such class exists.

=cut

sub backend_instance {
    my ($class, $type, %args) = @_;
    my $backend_class = $CLASSES{$type} or die 'unknown backend type ' . $type;
    return $backend_class->new(%args);
}

=head2 METHODS - For backend classes

These will be inherited by backend implementations and can be used
for some common actions when processing requests and responses.

=cut

=head2 new

    $backend = $class->new(%args)

Returns a new blessed HASH reference containing the given arguments.

=cut

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

=head2 make_call_params

Make RPC call params.

    $backend->make_call_params($c, $req_storage)

Method params:
    stash_params - it contains params to forward from server storage.

=cut

sub make_call_params {
    my ($self, $c, $req_storage) = @_;

    my $args         = $req_storage->{args};
    my $stash_params = $req_storage->{stash_params};

    my $call_params = $req_storage->{call_params};
    $call_params->{args} = $args;

    if (defined $stash_params) {
        $call_params->{$_} = $c->stash($_) for @$stash_params;
    }

    return $call_params;
}

=head2 get_rpc_response_cb

Returns the stored callback for this response if we have one, otherwise an empty list.

=cut

sub get_rpc_response_cb {
    my ($self, $c, $req_storage) = @_;

    my $success_handler = delete $req_storage->{success};
    my $error_handler   = delete $req_storage->{error};

    if (my $rpc_response_cb = delete $req_storage->{rpc_response_cb}) {
        return sub {
            my $rpc_response = shift;
            return $rpc_response_cb->($c, $rpc_response, $req_storage);
        };
    } else {
        return sub {
            my $rpc_response = shift;
            if (ref($rpc_response) eq 'HASH' and exists $rpc_response->{error}) {
                $error_handler->($c, $rpc_response, $req_storage) if defined $error_handler;
                return error_api_response($c, $rpc_response, $req_storage);
            } else {
                $success_handler->($c, $rpc_response, $req_storage) if defined $success_handler;
                store_response($c, $rpc_response);
                return success_api_response($c, $rpc_response, $req_storage);
            }
            return;
        };
    }
    return;
}

=head2 store_response

Save RPC response to storage.

=cut

sub store_response {
    my ($c, $rpc_response) = @_;

    if (ref($rpc_response) eq 'HASH' && $rpc_response->{stash}) {
        $c->stash(%{delete $rpc_response->{stash}});
    }
    return;
}

=head2 success_api_response

Make wsapi proxy server response from RPC response.

=cut

sub success_api_response {
    my ($c, $rpc_response, $req_storage) = @_;

    my $msg_type             = $req_storage->{msg_type};
    my $rpc_response_handler = $req_storage->{response};

    my $api_response = {
        msg_type  => $msg_type,
        $msg_type => $rpc_response,
    };

    if (ref($rpc_response) eq 'HASH' and keys %$rpc_response == 1 and exists $rpc_response->{status}) {
        $api_response->{$msg_type} = $rpc_response->{status};
    }

    if ($rpc_response_handler) {
        return $rpc_response_handler->($rpc_response, $api_response, $req_storage);
    }

    return $api_response;
}

=head2 error_api_response

Make wsapi proxy server response from RPC response.

=cut

sub error_api_response {
    my ($c, $rpc_response, $req_storage) = @_;

    my $msg_type             = $req_storage->{msg_type};
    my $rpc_response_handler = $req_storage->{response};
    my $api_response =
        $c->wsp_error($msg_type, $rpc_response->{error}->{code}, $rpc_response->{error}->{message_to_client}, $rpc_response->{error}->{details});

    if ($rpc_response_handler) {
        return $rpc_response_handler->($rpc_response, $api_response, $req_storage);
    }

    return $api_response;
}

=head1 REQUIRED METHODS - subclasses must implement

=cut

=head2 call_rpc

    $f = $backend->call_rpc($c, $req_storage)

Invoked to actually dispatch a given RPC method call to the backend.

=cut

1;
