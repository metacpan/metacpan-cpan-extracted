package Net::Blossom::Server::PSGI;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server;
use Net::Blossom::Server::Authorization;
use Net::Blossom::Server::Error;
use Net::Blossom::Server::Request;
use Net::Blossom::Server::Response;

use Carp qw(croak);
use Class::Tiny qw(server authorize authorization);
use Scalar::Util qw(blessed);

my %CORS_HEADERS = (
    'Access-Control-Allow-Origin' => '*',
);

my %PREFLIGHT_HEADERS = (
    'Access-Control-Allow-Headers' => 'Authorization, *',
    'Access-Control-Allow-Methods' => 'GET, HEAD, PUT, DELETE',
    'Access-Control-Max-Age'       => 86400,
);

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(server authorize authorization);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "server is required" unless defined $args{server};
    croak "server must be a Net::Blossom::Server"
        unless blessed($args{server}) && $args{server}->isa('Net::Blossom::Server');

    croak "authorize must be a code reference"
        if defined $args{authorize} && ref($args{authorize}) ne 'CODE';
    croak "authorization must be a Net::Blossom::Server::Authorization"
        if defined $args{authorization}
        && !(blessed($args{authorization}) && $args{authorization}->isa('Net::Blossom::Server::Authorization'));
    croak "authorize and authorization are mutually exclusive"
        if defined $args{authorize} && defined $args{authorization};

    return bless \%args, $class;
}

sub to_app {
    my ($self) = @_;

    return sub {
        my ($env) = @_;
        my $request = eval { _request_from_env($env) };
        return _exception_to_psgi($@, 400, 'Bad Request') if $@;

        return _response_to_psgi(_preflight_response())
            if $request->method eq 'OPTIONS';

        my %opts;

        my $response = eval {
            if (defined $self->authorization) {
                my $authorization = $self->authorization->authorize($request);
                if (defined $authorization) {
                    $opts{pubkey} = $authorization->pubkey;
                    $opts{authorization} = $authorization;
                }
            }
            elsif (defined $self->authorize) {
                my $pubkey = $self->authorize->(
                    request => $request,
                    env     => $env,
                );
                $opts{pubkey} = $pubkey if defined $pubkey;
            }

            $self->server->handle_request($request, %opts);
        };
        return _exception_to_psgi($@, 500, 'Internal Server Error') if $@;

        return _response_to_psgi($response);
    };
}

sub _request_from_env {
    my ($env) = @_;
    croak "env must be a hash reference" unless ref($env) eq 'HASH';

    my %args = (
        method  => $env->{REQUEST_METHOD},
        path    => defined($env->{PATH_INFO}) && length($env->{PATH_INFO}) ? $env->{PATH_INFO} : '/',
        headers => _headers_from_env($env),
        query   => _query_from_env($env),
    );

    $args{body} = $env->{'psgi.input'} if defined $env->{'psgi.input'};
    $args{remote_addr} = $env->{REMOTE_ADDR} if defined $env->{REMOTE_ADDR};
    $args{content_type} = $env->{CONTENT_TYPE}
        if defined($env->{CONTENT_TYPE}) && length($env->{CONTENT_TYPE});
    $args{content_length} = $env->{CONTENT_LENGTH}
        if defined($env->{CONTENT_LENGTH}) && length($env->{CONTENT_LENGTH});

    return Net::Blossom::Server::Request->new(%args);
}

sub _response_to_psgi {
    my ($response) = @_;
    croak "response must be a Net::Blossom::Server::Response"
        unless blessed($response) && $response->isa('Net::Blossom::Server::Response');

    my $body = $response->body;
    $body = [$body] unless ref($body);
    return [$response->status, _header_pairs_with_cors($response), $body];
}

sub _preflight_response {
    return Net::Blossom::Server::Response->empty(204, headers => \%PREFLIGHT_HEADERS);
}

sub _header_pairs_with_cors {
    my ($response) = @_;
    my $headers = $response->headers;

    for my $name (keys %CORS_HEADERS) {
        my $lower = lc $name;
        for my $existing (keys %$headers) {
            delete $headers->{$existing} if lc($existing) eq $lower;
        }
        $headers->{$name} = $CORS_HEADERS{$name};
    }

    my @pairs;
    for my $name (sort keys %$headers) {
        push @pairs, $name, $headers->{$name};
    }
    return \@pairs;
}

sub _exception_to_psgi {
    my ($error, $status, $reason) = @_;

    my $response;
    if (blessed($error) && $error->isa('Net::Blossom::Server::Error')) {
        $response = $error->as_response;
    }
    else {
        $response = Net::Blossom::Server::Response->error($status, $reason);
    }

    return _response_to_psgi($response);
}

sub _headers_from_env {
    my ($env) = @_;
    my %headers;

    $headers{'Content-Type'} = $env->{CONTENT_TYPE}
        if defined($env->{CONTENT_TYPE}) && length($env->{CONTENT_TYPE});
    $headers{'Content-Length'} = $env->{CONTENT_LENGTH}
        if defined($env->{CONTENT_LENGTH}) && length($env->{CONTENT_LENGTH});

    for my $key (sort keys %$env) {
        next unless $key =~ /\AHTTP_(.+)\z/;
        my $name = _header_name_from_env($1);
        $headers{$name} = $env->{$key};
    }

    return \%headers;
}

sub _header_name_from_env {
    my ($name) = @_;
    return join '-', map { ucfirst lc $_ } split /_/, $name;
}

sub _query_from_env {
    my ($env) = @_;
    my $query_string = $env->{QUERY_STRING};
    return {} unless defined($query_string) && length($query_string);

    my %query;
    for my $pair (split /&/, $query_string, -1) {
        next unless length $pair;
        my ($name, $value) = split /=/, $pair, 2;
        $name = _decode_query_component($name);
        $value = defined $value ? _decode_query_component($value) : '';

        if (exists $query{$name}) {
            $query{$name} = [$query{$name}] unless ref($query{$name}) eq 'ARRAY';
            push @{$query{$name}}, $value;
        }
        else {
            $query{$name} = $value;
        }
    }

    return \%query;
}

sub _decode_query_component {
    my ($value) = @_;
    $value =~ tr/+/ /;
    croak "invalid query percent encoding" if $value =~ /%(?![0-9A-Fa-f]{2})/;
    $value =~ s/%([0-9A-Fa-f]{2})/chr hex $1/eg;
    return $value;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::PSGI - PSGI adapter for the Blossom server core

=head1 SYNOPSIS

    use Net::Blossom::Server::PSGI;

    my $app = Net::Blossom::Server::PSGI->new(
        server    => $server,
        authorize => sub {
            my %ctx = @_;
            return $pubkey;
        },
    )->to_app;

=head1 DESCRIPTION

C<Net::Blossom::Server::PSGI> turns a C<Net::Blossom::Server> object into a
PSGI application code reference. It does not depend on Plack and does not choose
an HTTP daemon for the application.

The adapter translates the PSGI environment into a
C<Net::Blossom::Server::Request>, applies optional authorization, and passes the
request into C<Net::Blossom::Server>. The returned
C<Net::Blossom::Server::Response> is translated into the PSGI response array.

CORS headers required by BUD-01 are added to every PSGI response. C<OPTIONS>
requests are handled directly by this adapter as CORS preflight requests and do
not reach authorization or server route dispatch.

Malformed requests are returned as C<400> responses. Typed
C<Net::Blossom::Server::Error> exceptions are returned with their configured
status and headers. Other exceptions are returned as generic C<500> responses.

=head1 CONSTRUCTOR

=head2 new

    my $adapter = Net::Blossom::Server::PSGI->new(%args);

Required arguments:

=over 4

=item * C<server>

A C<Net::Blossom::Server> object.

=back

Optional arguments:

=over 4

=item * C<authorize>

Code reference called before dispatch. It receives C<request> and C<env> named
arguments. When it returns a defined value, that value is passed to the server
core as the verified C<pubkey>.

=item * C<authorization>

A C<Net::Blossom::Server::Authorization> object. When supplied, the adapter
validates BUD-11 C<Authorization> headers for implemented Blossom endpoints and
passes the verified event pubkey and authorization result to the server core.

=back

Unknown arguments or invalid values croak. C<authorize> and C<authorization> are
mutually exclusive.

=head1 ACCESSORS

=head2 server

Returns the C<Net::Blossom::Server> object.

=head2 authorize

Returns the optional authorization callback.

=head2 authorization

Returns the optional BUD-11 authorization verifier.

=head1 METHODS

=head2 to_app

    my $app = $adapter->to_app;

Returns a PSGI application code reference.

=cut
