package Pcore::API::Client;

use Pcore -class, -result;
use Pcore::WebSocket;
use Pcore::Util::Data qw[to_json from_json to_cbor from_cbor];
use Pcore::Util::UUID qw[uuid_str];

has uri => ( is => 'ro', isa => Str | InstanceOf ['Pcore::Util::URI'], required => 1 );    # http://token@host:port/api/, ws://token@host:port/api/

has token             => ( is => 'lazy', isa => Str );
has api_ver           => ( is => 'ro',   isa => Str );                                     # default API version for relative methods
has keepalive_timeout => ( is => 'ro',   isa => Maybe [PositiveOrZeroInt] );
has http_timeout      => ( is => 'ro',   isa => Maybe [PositiveOrZeroInt] );
has http_tls_ctx      => ( is => 'ro',   isa => Maybe [ HashRef | Int ] );

has _uri => ( is => 'lazy', isa => InstanceOf ['Pcore::Util::URI'], init_arg => undef );
has _is_http => ( is => 'lazy', isa => Bool, init_arg => undef );
has _ws => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::WebSocket'], init_arg => undef );
has _ws_connect_cache => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );
has _ws_tid_cache     => ( is => 'ro', isa => HashRef,  default => sub { {} }, init_arg => undef );

around BUILDARGS => sub ( $orig, $self, $uri, @ ) {
    my %args = ( splice @_, 3 );

    $args{uri} = $uri;

    return $self->$orig( \%args );
};

sub _build__uri($self) {
    return P->uri( $self->uri );
}

sub _build_token ($self) {
    return $self->_uri->userinfo;
}

sub _build__is_http ($self) {
    return $self->_uri->is_http;
}

# TODO make blocking call
sub api_call ( $self, $method, @ ) {

    # add version to relative method id
    if ( substr( $method, 0, 1 ) ne q[/] ) {
        if ( $self->{api_ver} ) {
            $method = "/$self->{api_ver}/$method";
        }
        else {
            die qq[You need to defined default "api_ver" to use relative methods names];
        }
    }

    # HTTP protocol
    if ( $self->_is_http ) {
        my ( $cb, $data );

        # parse callback
        if ( ref $_[-1] eq 'CODE' ) {
            $cb = $_[-1];

            $data = [ @_[ 2 .. $#_ - 1 ] ];
        }
        else {
            $data = [ @_[ 2 .. $#_ ] ];
        }

        P->http->post(
            $self->_uri,
            keepalive_timeout => $self->keepalive_timeout,
            ( $self->http_timeout ? ( timeout => $self->http_timeout ) : () ),
            ( $self->http_tls_ctx ? ( tls_ctx => $self->http_tls_ctx ) : () ),
            headers => {
                REFERER       => undef,
                AUTHORIZATION => 'token ' . $self->token,
                CONTENT_TYPE  => 'application/cbor',
            },
            body => to_cbor(
                {   type   => 'rpc',
                    tid    => uuid_str(),
                    method => $method,
                    data   => $data,
                }
            ),
            on_finish => sub ($res) {

                if ($cb) {

                    # HTTP protocol error
                    if ( !$res ) {
                        $cb->( result [ $res->status, $res->reason ] );
                    }
                    else {
                        my $res_data = from_cbor $res->body;

                        if ( $res_data->[0]->{type} eq 'exception' ) {
                            $cb->( bless $res_data->[0]->{message}, 'Pcore::Util::Result' );
                        }
                        else {
                            $cb->( bless $res_data->[0]->{result}, 'Pcore::Util::Result' );
                        }
                    }
                }

                return;
            },
        );
    }

    # WebSocket protocol
    else {
        my $cb;

        if ( ref $_[-1] eq 'CODE' ) {
            $cb = $_[-1];
        }

        my $on_connect = sub ( $h ) {
            $h->rpc_call( $method, @_[ 2 .. $#_ ] );

            return;
        };

        my $ws = $self->{_ws};

        if ( !$ws ) {
            my $on_error = sub ( $status, $reason ) {
                $cb->( result [ $status, $reason ] ) if $cb;

                return;
            };

            push $self->{_ws_connect_cache}->@*, [ $on_error, $on_connect ];

            return if $self->{_ws_connect_cache}->@* > 1;

            Pcore::WebSocket->connect_ws(
                'pcore'         => $self->_uri,
                headers         => [ 'Authorization' => 'token ' . $self->token, ],
                connect_timeout => 10,
                ( $self->http_timeout ? ( timeout => $self->http_timeout ) : () ),
                ( $self->http_tls_ctx ? ( tls_ctx => $self->http_tls_ctx ) : () ),
                on_proxy_connect_error => sub ( $status, $reason ) {
                    while ( my $callback = shift $self->{_ws_connect_cache}->@* ) {
                        $callback->[0]->( $status, $reason );
                    }

                    return;
                },
                on_connect_error => sub ( $status, $reason ) {
                    while ( my $callback = shift $self->{_ws_connect_cache}->@* ) {
                        $callback->[0]->( $status, $reason );
                    }

                    return;
                },
                on_connect => sub ( $ws, $headers ) {
                    $self->{_ws} = $ws;

                    while ( my $callback = shift $self->{_ws_connect_cache}->@* ) {
                        $callback->[1]->($ws);
                    }

                    return;
                },
                on_disconnect => sub ( $ws, $status, $reason ) {
                    undef $self->{_ws};

                    return;
                },
                on_rpc_call => sub ( $h, $req, $method, $data ) {
                    return;
                },
            );
        }
        else {
            $on_connect->($ws);
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 43                   | Subroutines::ProhibitExcessComplexity - Subroutine "api_call" with high complexity score (25)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 51                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Client

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
