package Net::WebSocket::Handshake::Server;

=encoding utf-8

=head1 NAME

Net::WebSocket::Handshake::Server

=head1 SYNOPSIS

    my $hsk = Net::WebSocket::Handshake::Server->new(

        #optional
        subprotocols => [ 'echo', 'haha' ],

        #optional
        extensions => \@extension_objects,
    );

    $hsk->valid_method_or_die( $http_method );  #optional

    $hsk->consume_headers(@headers_kv_pairs);

    my $resp_hdr = $hsk->to_string();

=head1 DESCRIPTION

This class implements WebSocket handshake logic for a server.
It handles the basics of handshaking and, optionally, subprotocol
and extension negotiation.

=cut

use strict;
use warnings;

use parent qw( Net::WebSocket::Handshake );

use Call::Context ();
use Digest::SHA ();

use Net::WebSocket::Constants ();
use Net::WebSocket::X ();

#no-op
use constant _handle_unrecognized_extension => ();

=head2 I<CLASS>->new( %OPTS )

Returns an instance of this class. %OPTS is as described in the base class;
there are no options specific to this class.

=head2 I<OBJ>->valid_protocol_or_die( PROTOCOL )

Throws an exception if the given PROTOCOL isn’t the HTTP protocol (HTTP/1.1)
that WebSocket requires for all requests.

You only need this if if you’re not using a request-parsing interface
that’s compatible with L<HTTP::Request>; otherwise,
L<Net::WebSocket::HTTP_R>’s C<handshake_consume_request()> function
will do this (and other niceties) for you.

=cut

sub valid_protocol_or_die {
    my ($self, $protocol) = @_;

    if ($protocol ne Net::WebSocket::Constants::REQUIRED_REQUEST_PROTOCOL()) {
        die Net::WebSocket::X->create('BadRequestProtocol', $protocol);
    }

    return;
}

=head2 I<OBJ>->valid_method_or_die( METHOD )

Throws an exception if the given METHOD isn’t the HTTP method (GET) that
WebSocket requires for all requests.

As with C<valid_protocol_or_die()>, L<Net::WebSocket::HTTP_R> might
call this method for you.

=cut

sub valid_method_or_die {
    my ($self, $method) = @_;

    if ($method ne Net::WebSocket::Constants::REQUIRED_HTTP_METHOD()) {
        die Net::WebSocket::X->create('BadHTTPMethod', $method);
    }

    return;
}

sub _consume_peer_header {
    my ($self, $name => $value) = @_;

    $name =~ tr<A-Z><a-z>;  #case insensitive

    if ($name eq 'sec-websocket-version') {
        if ( $value ne Net::WebSocket::Constants::PROTOCOL_VERSION() ) {
            die Net::WebSocket::X->create('UnsupportedProtocolVersion', $value);
        }

        $self->{'_version_ok'} = 1;
    }
    elsif ($name eq 'sec-websocket-key') {
        $self->{'key'} = $value;
    }
    elsif ($name eq 'sec-websocket-protocol') {
        Module::Load::load('Net::WebSocket::HTTP');

        for my $token ( Net::WebSocket::HTTP::split_tokens($value) ) {
            if (!defined $self->{'_subprotocol'}) {
                ($self->{'_subprotocol'}) = grep { $_ eq $token } @{ $self->{'subprotocols'} };
            }
        }
    }
    else {
        $self->_consume_generic_header($name => $value);
    }

    return;
}

#Send only those extensions that we’ve deduced the client can actually use.
sub _should_include_extension_in_headers {
    my ($self, $xtn) = @_;

    return $xtn->ok_to_use();
}

sub _encode_subprotocols {
    my ($self) = @_;

    local $self->{'subprotocols'} = defined($self->{'_subprotocol'}) ? [ $self->{'_subprotocol'} ] : undef if $self->{'_no_use_legacy'};

    return $self->SUPER::_encode_subprotocols();
}

sub _valid_headers_or_die {
    my ($self) = @_;

    my @needed = $self->_missing_generic_headers();

    push @needed, 'Sec-WebSocket-Version' if !$self->{'_version_ok'};
    push @needed, 'Sec-WebSocket-Key' if !$self->{'key'};

    die "Need: [@needed]" if @needed;

    return;
}

sub _create_header_lines {
    my ($self) = @_;

    Call::Context::must_be_list();

    return (
        'HTTP/1.1 101 Switching Protocols',

        #For now let’s assume no one wants any other Upgrade:
        #or Connection: values than the ones WebSocket requires.
        'Upgrade: websocket',
        'Connection: Upgrade',

        'Sec-WebSocket-Accept: ' . $self->get_accept(),

        $self->_encode_subprotocols(),

        $self->_encode_extensions(),
    );
}

#----------------------------------------------------------------------

=head1 LEGACY INTERFACE: SYNOPSIS

    #...Parse the request’s headers yourself...

    my $hsk = Net::WebSocket::Handshake::Server->new(

        #base 64, gotten from request
        key => '..',

        #optional - same as in non-legacy interface
        subprotocols => [ 'echo', 'haha' ],

        #optional, instances of Net::WebSocket::Handshake::Extension
        extensions => \@extension_objects,
    );

    #Note the need to conclude the header text manually.
    print $hsk->create_header_text() . "\x0d\x0a";

=cut

*get_accept = __PACKAGE__->can('_get_accept');

1;
