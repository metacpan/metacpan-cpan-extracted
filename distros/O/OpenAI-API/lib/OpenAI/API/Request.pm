package OpenAI::API::Request;

use IO::Async::Loop;
use IO::Async::Future;
use JSON::MaybeXS;
use LWP::UserAgent;

use Moo;
use strictures 2;
use namespace::clean;

use OpenAI::API::Config;
use OpenAI::API::Error;

has 'config' => (
    is      => 'ro',
    default => sub { OpenAI::API::Config->new() },
    isa     => sub {
        die "config must be an instance of OpenAI::API::Config"
            unless ref $_[0] eq 'OpenAI::API::Config';
    },
    coerce => sub {
        return $_[0] if ref $_[0] eq 'OpenAI::API::Config';
        return OpenAI::API::Config->new( %{ $_[0] } );
    },
);

has 'user_agent' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_user_agent',
);

has 'event_loop' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_event_loop',
);

sub _build_user_agent {
    my ($self) = @_;
    $self->{user_agent} = LWP::UserAgent->new( timeout => $self->config->timeout );
}

sub _build_event_loop {
    my ($self) = @_;
    my $class = $self->config->event_loop_class;
    eval "require $class" or die "Failed to load event loop class $class: $@";
    return $class->new();
}

sub endpoint {
    die "Must be implemented";
}

sub method {
    die "Must be implemented";
}

sub _parse_response {
    my ( $self, $res ) = @_;

    my $class = ref $self || $self;

    # Replace s/Request/Response/ to find the response module
    ( my $response_module = $class ) =~ s/Request/Response/;

    # Require the OpenAI::API::Response module
    eval "require $response_module" or die $@;

    # Return the OpenAI::API::Response object
    my $decoded_res = decode_json( $res->decoded_content );
    return $response_module->new($decoded_res);
}

sub request_params {
    my ($self) = @_;
    my %request_params = %{$self};
    delete $request_params{config};
    delete $request_params{user_agent};
    delete $request_params{event_loop};
    return \%request_params;
}

sub send {
    my $self = shift;

    if ( @_ == 1 ) {
        warn "Sending config via send is deprecated. More info: perldoc OpenAI::API::Config\n";
    }

    my %args = @_;

    my $res =
          $self->method eq 'POST' ? $self->_post()
        : $self->method eq 'GET'  ? $self->_get()
        :                           die "Invalid method";

    if ( $args{http_response} ) {
        return $res;
    }

    return $self->_parse_response($res);
}

sub _get {
    my ($self) = @_;

    my $req = $self->_create_request('GET');
    return $self->_send_request($req);
}

sub _post {
    my ($self) = @_;

    my $req = $self->_create_request( 'POST', encode_json( $self->request_params() ) );
    return $self->_send_request($req);
}

sub send_async {
    my ( $self, %args ) = @_;

    my $res_future =
          $self->method eq 'POST' ? $self->_post_async()
        : $self->method eq 'GET'  ? $self->_get_async()
        :                           die "Invalid method";

    if ( $args{http_response} ) {
        return $res_future;
    }

    # Return a new future that resolves to $res->decoded_content
    my $decoded_content_future = $res_future->then(
        sub {
            my $res = shift;
            return $self->_parse_response($res);
        }
    );

    return $decoded_content_future;
}

sub _get_async {
    my ($self) = @_;

    my $req = $self->_create_request('GET');
    return $self->_send_request_async($req);
}

sub _post_async {
    my ( $self, $config ) = @_;

    my $req = $self->_create_request( 'POST', encode_json( $self->request_params() ) );
    return $self->_send_request_async($req);
}

sub _create_request {
    my ( $self, $method, $content ) = @_;

    my $req = HTTP::Request->new(
        $method => $self->config->api_base . "/" . $self->endpoint,
        $self->_request_headers(),
        $content,
    );

    return $req;
}

sub _request_headers {
    my ($self) = @_;

    return [
        'Content-Type'  => 'application/json',
        'Authorization' => 'Bearer ' . $self->config->api_key,
    ];
}

sub _send_request {
    my ( $self, $req ) = @_;

    my $loop = IO::Async::Loop->new();

    my $future = $self->_async_http_send_request($req);

    $loop->await($future);

    my $res = $future->get;

    if ( !$res->is_success ) {
        OpenAI::API::Error->throw(
            message  => "Error: '@{[ $res->status_line ]}'",
            request  => $req,
            response => $res,
        );
    }

    return $res;
}

sub _send_request_async {
    my ( $self, $req ) = @_;

    return $self->_async_http_send_request($req)->then(
        sub {
            my $res = shift;

            if ( !$res->is_success ) {
                OpenAI::API::Error->throw(
                    message  => "Error: '@{[ $res->status_line ]}'",
                    request  => $req,
                    response => $res,
                );
            }

            return $res;
        }
    )->catch(
        sub {
            my $err = shift;
            die $err;
        }
    );
}

sub _http_send_request {
    my ( $self, $req ) = @_;

    for my $attempt ( 1 .. $self->config->retry ) {
        my $res = $self->user_agent->request($req);

        if ( $res->is_success ) {
            return $res;
        } elsif ( $res->code =~ /^(?:500|503|504|599)$/ && $attempt < $self->config->retry ) {
            sleep( $self->config->sleep );
        } else {
            return $res;
        }
    }
}

sub _async_http_send_request {
    my ( $self, $req ) = @_;

    my $future = IO::Async::Future->new;

    $self->event_loop->later(
        sub {
            eval {
                my $res = $self->_http_send_request($req);
                $future->done($res);
                1;
            } or do {
                my $err = $@;
                $future->fail($err);
            };
        }
    );

    return $future;
}

1;

__END__

=head1 NAME

OpenAI::API::Request - Base module for making requests to the OpenAI API

=head1 SYNOPSIS

This module is a base module for making HTTP requests to the OpenAI
API. It should not be used directly.

    package OpenAI::API::Request::NewRequest;
    use Moo;
    extends 'OpenAI::API::Request';

    sub endpoint {
        '/my_endpoint'
    }

    sub method {
        'POST'
    }

    # somewhere else...

    use OpenAI::API::Request::NewRequest;

    my $req = OpenAI::API::Request::NewRequest->new(...);

    my $res = $req->send();    # or: my $res = $req->send_async();

=head1 DESCRIPTION

This module provides a base class for creating request objects for the
OpenAI API. It includes methods for sending synchronous and asynchronous
requests, with support for HTTP GET and POST methods.

=head1 ATTRIBUTES

=head2 config

An instance of L<OpenAI::API::Config> that provides configuration
options for the OpenAI API client. Defaults to a new instance of
L<OpenAI::API::Config>.

=head2 user_agent

An instance of L<LWP::UserAgent> that is used to make HTTP
requests. Defaults to a new instance of L<LWP::UserAgent> with a timeout
set to the value of C<config-E<gt>timeout>.

=head2 event_loop

An instance of an event loop class, specified by
C<config-E<gt>event_loop_class> option.

=head1 METHODS

=head2 endpoint

This method must be implemented by subclasses. It should return the API
endpoint for the specific request.

=head2 method

This method must be implemented by subclasses. It should return the HTTP
method for the specific request.

=head2 send(%args)

This method sends the request and returns the parsed response. If the
'http_response' key is present in the %args hash, it returns the raw
L<HTTP::Response> object instead of the parsed response.

    my $response = $request->send();

    my $response = $request->send( http_response => 1 );

=head2 send_async(%args)

This method sends the request asynchronously and returns a
L<IO::Async::Future> object. If the 'http_response' key is present in
the %args hash, it resolves to the raw L<HTTP::Response> object instead
of the parsed response.

Here's an example usage:

    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new();

    my $future = $request->send_async()->then(
        sub {
            my $content = shift;
            # ...
        }
    )->catch(
        sub {
            my $error = shift;
            # ...
        }
    );

    $loop->await($future);

    my $res = $future->get;

Note: if you want to use a different event loop, you must pass it via
the L<config|OpenAI::API::Config> attribute.
