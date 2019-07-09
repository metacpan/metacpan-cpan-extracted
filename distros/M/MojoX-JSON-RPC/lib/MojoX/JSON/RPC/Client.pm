package MojoX::JSON::RPC::Client;

use Mojo::Base -base;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::UserAgent;

has id           => undef;
has ua           => sub { Mojo::UserAgent->new };
has version      => '2.0';
has content_type => 'application/json';
has tx           => undef;                          # latest transaction

sub call {
    my ( $self, $uri, $body, $callback ) = @_;

    # body might be json already, only encode if necessary
    if ( ref $body eq 'HASH' || ref $body eq 'ARRAY' ) {
        foreach my $o ( ref $body eq 'HASH' ? $body : @{$body} ) {
            $o->{version} ||= $self->version;
        }
        $body = encode_json($body);
    }
    else {
        $body ||= q{};
    }

    # Always POST if $body is not empty!
    if ( ref $callback ne 'CODE' ) {
        if ( $body ne q{} ) {
            return $self->_process_result(
                $self->ua->post(
                    $uri, { 'Content-Type' => $self->content_type }, $body
                )
            );
        }
        elsif ( $uri =~ /\?/xms ) {
            return $self->_process_result( $self->ua->get($uri) );
        }
    }
    else {    # non-blocking
        if ( $body ne q{} ) {
            $self->ua->post(
                $uri,
                { 'Content-Type' => $self->content_type },
                $body,
                sub {    # callback
                    $callback->( $self->_process_result(pop) );
                },
            );
            return;
        }
        elsif ( $uri =~ /\?/xms ) {
            $self->ua->get(
                $uri => sub {    # callback
                    $callback->( $self->_process_result(pop) );
                }
            );
            return;
        }
    }
    return Carp::croak 'Cannot process call!';
}

# Prepare a Proxy object
sub prepare {
    my $self = shift;

    my %m = ();
URI:
    while ( my $uri = shift ) {
        my $methods = shift;

        # methods can be a name, a reference to a name or
        # a reference to an array of names
        if ( ref $methods eq 'SCALAR' ) {
            $methods = [$$methods];
        }
        elsif ( defined $methods && ref $methods eq q{} ) {
            $methods = [$methods];
        }
        if ( ref $methods ne 'ARRAY' ) {
            last URI;
        }
    METHOD:
        foreach my $method ( @{$methods} ) {
            if ( exists $m{$method} && $m{$method} ne $uri ) {
                Carp::croak qq{Cannot register method $method twice!};
            }
            $m{$method} = $uri;
        }
    }
    return bless {
        client  => $self,
        methods => \%m
        },
        'MojoX::JSON::RPC::Client::Proxy';
}

sub _process_result {
    my ( $self, $tx ) = @_;

    $self->tx($tx);    # save latest transaction

    my $tx_res = $tx->res;
    my $log = $self->ua->server->app->log if $self->ua->server->app;
    if ( $log && $log->is_level('debug') ) {
        $log->debug( 'TX BODY: [' . $tx_res->body . ']' );
    }

    # Check if RPC call is succesfull
    if ( !( $tx_res->is_success || $tx_res->is_client_error ) )
    {
        return;
    }

    my $decode_error;
    my $rpc_res;
    
    eval{ $rpc_res = decode_json( $tx_res->body || '{}' ); 1; } or $decode_error = $@;
    if ( $decode_error && $log ) {    # Server result cannot be parsed!
        $log->error( 'Cannot parse rpc result: ' . $decode_error );
        return;
    }

    # Return one or more ReturnObject's
    return ref $rpc_res eq 'ARRAY'
        ? [
        map {
            MojoX::JSON::RPC::Client::ReturnObject->new( rpc_response => $_ )
        } ( @{$rpc_res} )
        ]
        : MojoX::JSON::RPC::Client::ReturnObject->new(
        rpc_response => $rpc_res );
}

package MojoX::JSON::RPC::Client::Proxy;

use Carp;
use warnings;
use strict;

# no constructor defined. Object creation
# done by MojoX::JSON::RPC::Client.

our $AUTOLOAD;

# Dispatch calls
sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    # We do not want to overload DESTROY
    if ( $method eq 'DESTROY' ) {
        return;
    }

    if ( !exists $self->{methods}->{$method} ) {
        Carp::croak "Unsupported method $method";
    }

    my $res = $self->{client}->call(
        $self->{methods}->{$method},
        {   id     => $self->{id}++,
            method => $method,
            params => \@_
        }
    );
    return defined $res ? $res->result : ();
}

package MojoX::JSON::RPC::Client::ReturnObject;

use Mojo::Base -base;

has rpc_response => undef;    # rpc response

sub result {
    my ($self) = @_;
    my $rpc_response = $self->rpc_response;
    return
        ref $rpc_response eq 'HASH' && exists $rpc_response->{result}
        ? $rpc_response->{result}
        : undef;
}

sub id {
    my ($self) = @_;
    my $rpc_response = $self->rpc_response;
    return
        ref $rpc_response eq 'HASH' && exists $rpc_response->{id}
        ? $rpc_response->{id}
        : undef;
}

sub is_error {
    my ($self) = @_;
    my $rpc_response = $self->rpc_response;
    return ref $rpc_response eq 'HASH' && exists $rpc_response->{error}
        ? 1
        : 0;
}

sub error_code {
    my ($self) = @_;
    return $self->is_error ? $self->rpc_response->{error}->{code} : undef;
}

sub error_message {
    my ($self) = @_;
    return $self->is_error ? $self->rpc_response->{error}->{message} : undef;
}

sub error_data {
    my ($self) = @_;
    return $self->is_error ? $self->rpc_response->{error}->{data} : undef;
}

1;

__END__

=head1 NAME

MojoX::JSON::RPC::Client - JSON RPC client

=head1 SYNOPSIS

    use MojoX::JSON::RPC::Client;

    my $client = MojoX::JSON::RPC::Client->new;
    my $url    = 'http://www.example.com/jsonrpc/API';
    my $callobj = {
        id      => 1,
        method  => 'sum',
        params  => [ 17, 25 ]
    };

    my $res = $client->call($url, $callobj);

    if($res) {
        if ($res->is_error) { # RPC ERROR
            print 'Error : ', $res->error_message;
        }
        else {
            print $res->result;
        }
    }
    else {
        my $tx_res = $client->tx->res; # Mojo::Message::Response object
        print 'HTTP response '.$tx_res->code.' '.$tx_res->message;
    }

Non-blocking:

    $client->call($url, $callobj, sub {
        # With callback
        my $res = pop;

        # ... process result ...

        Mojo::IOLoop->stop;
    });

    Mojo::IOLoop->start;

Easy access:

    my $proxy = $client->prepare($uri, ['sum', 'echo']);

    print $proxy->sum(10, 23);


=head1 DESCRIPTION

A JSON-RPC client.

=head1 ATTRIBUTES

L<MojoX::JSON::RPC::Client> implements the following attributes.

=head2 C<id>

Id used for JSON-RPC requests. Used when no id is provided as request parameter.

=head2 C<ua>

L<Mojo::UserAgent> object.

=head2 C<json>

L<Mojo::JSON> object for encoding and decoding.

=head2 C<version>

JSON-RPC version. Defaults to 2.0.

=head2 C<content_type>

Content type. Defaults to application/json.

=head2 C<tx>

Mojo::Transaction object of last request.

=head1 METHODS

L<MojoX::JSON::RPC::Client> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<new>

Creates new MojoX::JSON::RPC::Client object.

    my $client = MojoX::JSON::RPC::Client->new;

=head2 C<call>

Execute JSON-RPC call. Returns L<MojoX::JSON::RPC::CLient::ReturnObject> if RPC call
is executed correctly.

    my $client = MojoX::JSON::RPC::Client->new;
    my $url    = 'http://www.example.com/jsonrpc/API';
    my $callobj = {
        id      => 1,
        method  => 'sum',
        params  => [ 17, 25 ]
    };

    my $res = $client->call($url, $callobj);
    if($res) {
        if ($res->is_error) { # RPC error
            print 'Error : ', $res->error_message;
        }
        else {
            print $res->result;
        }
    }
    else {
        my $tx_res = $client->tx->res; # Mojo::Message::Response object
        print 'HTTP response '.$tx_res->code.' '.$tx_res->message;
    }

Make non-blocking call:

    $client->call($url, $callobj, sub {
        # With callback
        my $res = pop;

        # ... process result ...

        Mojo::IOLoop->stop;
    });

    Mojo::IOLoop->start;

=head2 C<prepare>

Prepares a proxy object that allows RPC methods to be called
more easily.

    my $proxy = $client->prepare($uri, ['sum', 'echo']);

    my $res = $proxy->sum(1, 2);

    print $proxy->echo("Echo this!");

Register services from multiple urls at once:

    my $proxy = $client->prepare($uri1, 'sum', $uri2, [ 'echo', 'ping' ]);

    my $res = $proxy->sum(1, 2);

    print $proxy->echo("Echo this!");

    my $ping_res = $proxy->ping;

=head1 C<MojoX::JSON::RPC::CLient::ReturnObject>

This object is returned by C<call>.

=head2 C<result>

RPC result.

=head2 C<is_error>

Returns a boolean indicating whether an error code has been set.

=head2 C<error_code>

RPC error code.

=head2 C<error_message>

RPC error message.

=head2 C<error_data>

RPC error data.

=head1 SEE ALSO

L<MojoX::JSON::RPC>

=cut

