package Pcore::HTTP::Server::Request;

use Pcore -class, -const, -res;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_arrayref];
use Pcore::Util::HTTP;

use overload    #
  '&{}' => sub ( $self, @ ) {
    return sub { return _respond( $self, @_ ) };
  },
  fallback => 1;

has _server => ( required => 1 );    # InstanceOf ['Pcore::HTTP::Server']
has _h      => ( required => 1 );    # InstanceOf ['Pcore::Handle']
has env     => ( required => 1 );
has data    => ();
has keepalive => ();

has is_websocket_connect_request => ( is => 'lazy' );
has _response_status             => 0;
has _cb                          => ();                 # callback

const our $HTTP_SERVER_RESPONSE_STARTED  => 1;          # headers written
const our $HTTP_SERVER_RESPONSE_FINISHED => 2;          # body written

sub DESTROY ( $self ) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        if ( my $cb = $self->{_cb} ) {

            # request is destroyed without ->finish call
            if ( $self->{_response_status} != $HTTP_SERVER_RESPONSE_FINISHED ) {

                # HTTP headers was not written
                if ( !$self->{_response_status} ) {
                    $self->_return_xxx( 500, 1 );
                }
                else {
                    $cb->(1);
                }
            }
        }
    }

    return;
}

sub _respond ( $self, @args ) {
    die q[Unable to write, HTTP response is already finished] if $self->{_response_status} == $HTTP_SERVER_RESPONSE_FINISHED;

    my ( $buf, $body );

    # first call, $status, $headers, $body
    if ( !$self->{_response_status} ) {
        $self->{_response_status} = $HTTP_SERVER_RESPONSE_STARTED;

        $buf = $self->{_server}->build_response_headers(
            shift @args,
            shift @args,
            [   Connection          => $self->{keepalive} ? 'keep-alive' : 'close',
                'Transfer-Encoding' => 'chunked',                                     # always use chunked transfer
            ]
        );

        $buf->$* .= "\r\n";
    }

    $body = Pcore::Util::HTTP::build_body( \@args );

    $buf->$* .= sprintf "%x\r\n%s\r\n", length $body->$*, $body->$* if length $body->$*;

    $self->{_h}->write( $buf->$* ) if defined $buf;

    return $self;
}

sub finish ( $self, $trailing_headers = undef ) {
    my $response_status = $self->{_response_status};

    die q[Unable to finish already finished HTTP request] if $response_status == $HTTP_SERVER_RESPONSE_FINISHED;

    # HTTP headers are not written
    if ( !$response_status ) {

        # return 204 No Content - the server successfully processed the request and is not returning any content
        $self->_return_xxx( 204, 0 );
    }

    # HTTP headers are written
    else {

        # mark request as finished
        $self->{_response_status} = $HTTP_SERVER_RESPONSE_FINISHED;

        # write last chunk
        my $buf = "0\r\n";

        # write trailing headers
        # https://tools.ietf.org/html/rfc7230#section-3.2
        $buf .= ( join "\r\n", map {"$_->[0]:$_->[1]"} pairs $trailing_headers->@* ) . "\r\n" if $trailing_headers && $trailing_headers->@*;

        # close response
        $buf .= "\r\n";

        $self->{_h}->write($buf);

        if ( my $cb = delete $self->{_cb} ) { $cb->(0) }
    }

    return;
}

# return simple response and finish request
sub _return_xxx ( $self, $status, $close_connection ) {
    die q[Unable to finish already started HTTP request] if $self->{_response_status};

    # mark request as finished
    $self->{_response_status} = $HTTP_SERVER_RESPONSE_FINISHED;

    $self->{_server}->return_xxx( $self->{_h}, $status, $close_connection || !$self->{keepalive} );

    if ( my $cb = delete $self->{_cb} ) { $cb->($close_connection) }

    return;
}

# WEBSOCKET
sub _build_is_websocket_connect_request ( $self ) {
    my $env = $self->{env};

    return $env->{HTTP_UPGRADE} && $env->{HTTP_UPGRADE} =~ /websocket/smi && $env->{HTTP_CONNECTION} && $env->{HTTP_CONNECTION} =~ /\bupgrade\b/smi;
}

sub accept_websocket ( $self, $headers = undef ) {
    die q[Unable to finish already started HTTP request] if $self->{_response_status};

    # mark response as finished
    $self->{_response_status} = $HTTP_SERVER_RESPONSE_FINISHED;

    my $buf = $self->{_server}->build_response_headers(
        101, $headers,
        [   Connection       => 'upgrade',
            Upgrade          => 'websocket',
            'Content-Length' => 0,
        ]
    );

    my $h = delete $self->{_h};

    $h->write("$buf->$*\r\n");

    $self->{_cb}->(1);

    return $h;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Server::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
