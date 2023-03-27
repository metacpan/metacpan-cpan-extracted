package OpenAI::API::Request;

use AnyEvent;
use JSON::MaybeXS;
use LWP::UserAgent;
use Promises qw/deferred/;

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
);

has 'user_agent' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_user_agent',
);

sub _build_user_agent {
    my ($self) = @_;
    $self->{user_agent} = LWP::UserAgent->new( timeout => $self->config->timeout );
}

sub endpoint {
    die "Must be implemented";
}

sub method {
    die "Must be implemented";
}

sub request_params {
    my ($self) = @_;
    my %request_params = %{$self};
    delete $request_params{config};
    delete $request_params{user_agent};
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

    return decode_json( $res->decoded_content );
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

    my $res_promise =
          $self->method eq 'POST' ? $self->_post_async()
        : $self->method eq 'GET'  ? $self->_get_async()
        :                           die "Invalid method";

    if ( $args{http_response} ) {
        return $res_promise;
    }

    # Return a new promise that resolves to $res->decoded_content
    my $decoded_content_promise = $res_promise->then(
        sub {
            my $res = shift;
            return decode_json( $res->decoded_content );
        }
    );

    return $decoded_content_promise;
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

    my $cond_var = AnyEvent->condvar;

    $self->_async_http_send_request($req)->then(
        sub {
            $cond_var->send(@_);
        }
    )->catch(
        sub {
            $cond_var->send(@_);
        }
    );

    my $res = $cond_var->recv();

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

    my $d = deferred;

    AnyEvent::postpone {
        eval {
            my $res = $self->_http_send_request($req);
            $d->resolve($res);
            1;
        } or do {
            my $err = $@;
            $d->reject($err);
        };
    };

    return $d->promise();
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

=head1 DESCRIPTION

This module provides a base class for creating request objects for the
OpenAI API. It includes methods for sending synchronous and asynchronous
requests, with support for HTTP GET and POST methods.

=head1 ATTRIBUTES

=over 4

=item * config

An instance of L<OpenAI::API::Config> that provides configuration
options for the OpenAI API client. Defaults to a new instance of
L<OpenAI::API::Config>.

=item * user_agent

An instance of L<LWP::UserAgent> that is used to make HTTP
requests. Defaults to a new instance of L<LWP::UserAgent> with a timeout
set to the value of C<config-E<gt>timeout>.

=back

=head1 METHODS

=head2 endpoint

This method must be implemented by subclasses. It should return the API
endpoint for the specific request.

=head2 method

This method must be implemented by subclasses. It should return the HTTP
method for the specific request.

=head2 send

Send a request synchronously.

    my $response = $request->send();

=head2 send_async

Send a request asynchronously. Returns a L<Promises> promise that will
be resolved with the decoded JSON response.

Here's an example usage:

    my $cv = AnyEvent->condvar;    # Create a condition variable

    $request->send_async()->then(
        sub {
            my $response_data = shift;
            print "Response data: " . Dumper($response_data);
        }
    )->catch(
        sub {
            my $error = shift;
            print "$error\n";
        }
    )->finally(
        sub {
            print "Request completed\n";
            $cv->send();    # Signal the condition variable when the request is completed
        }
    );

    $cv->recv;              # Keep the script running until the request is completed.

=head1 SEE ALSO

L<OpenAI::API::Config>
