package Net::WebSocket::HTTP_R;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::HTTP_R - logic for HTTP::Request & HTTP::Response

=head1 SYNOPSIS

Client:

    my $resp = HTTP::Response->parse_string($http_response);

    my $handshake = Net::WebSocket::Handshake::Client->new( .. );

    Net::WebSocket::HTTP_R::handshake_consume_response( $handshake, $resp );

Server:

    my $req = HTTP::Request->parse_string($http_request);

    my $handshake = Net::WebSocket::Handshake::Server->new( .. );

    Net::WebSocket::HTTP_R::handshake_consume_request( $handshake, $req );

=head1 DESCRIPTION

Net::WebSocket is agnostic as to which tools an implementor may use to parse
HTTP headers. CPAN offers a number of options for doing this, and different
applications may have varying reasons to prefer one or the other—or an
entirely different approach altogether.

This module provides convenient logic for the L<HTTP::Request> and
L<HTTP::Response> CPAN modules. Any implementation that uses one of these
modules (or a compatible implementation) can use Net::WebSocket::HTTP_R and
save a bit of time.

=cut

sub handshake_consume_request {
    my ($hsk, $req) = @_;

    $hsk->valid_protocol_or_die( $req->protocol() );
    $hsk->valid_method_or_die( $req->method() );

    return _handshake_consume_common($hsk, $req);
}

sub handshake_consume_response {
    my ($hsk, $resp) = @_;

    $hsk->valid_status_or_die( $resp->code(), $resp->message() );

    return _handshake_consume_common($hsk, $resp);
}

sub _handshake_consume_common {
    my ($hsk, $r_obj) = @_;

    my $hdrs_obj = $r_obj->headers();

    my @hdrs;
    for my $hname ($hdrs_obj->header_field_names()) {
        my $value = $hdrs_obj->header($hname);
        if ('ARRAY' eq ref $value) {
            push @hdrs, $hname => $_ for @$value;
        }
        else {
            push @hdrs, $hname => $value;
        }
    }

    return $hsk->consume_headers(@hdrs);
}

1;
