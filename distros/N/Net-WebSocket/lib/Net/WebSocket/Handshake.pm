package Net::WebSocket::Handshake;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::Handshake - base class for handshake objects

=head1 DESCRIPTION

This base class’s L<Net::WebSocket::Handshake::Server> and
L<Net::WebSocket::Handshake::Client> subclasses implement
WebSocket’s handshake logic. They handle the basics of a WebSocket
handshake and, optionally, subprotocol and extension negotiation.

This base class is NOT directly instantiable.

=cut

use Digest::SHA ();
use HTTP::Headers::Util ();
use Module::Load ();

use Net::WebSocket::HTTP ();
use Net::WebSocket::X ();

use constant {
    _WS_MAGIC_CONSTANT => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11',
    CRLF => "\x0d\x0a",
};

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Returns an instance of the relevant subclass
(L<Net::WebSocket::Handshake::Client|::Client> or
L<Net::WebSocket::Handshake::Server|::Server>).
The following are common options for both:

=over

=item * C<subprotocols> - A list of HTTP tokens (e.g., C<wamp.2.json>)
that stand for subprotocols that this endpoint can use via the WebSocket
connection.

=item * C<extensions> - A list of extension objects that the Handshake
object will interact with to determine extension support.

=head1 COMMON EXTENSION INTERFACE

Each object in the C<extensions> array must implement the following methods:

=over

=item * C<token()> The extension’s token. (e.g., C<permessage-deflate>)

=item * C<get_handshake_object()> Returns an instance of
L<Net::WebSocket::Handshake::Extension> to represent the extension and
its parameters in the HTTP headers.

=item * C<consume_parameters(..)> Receives the extension parameters
(in the format that C<Net::WebSocket::Handshake::Extension::parameters()>
returns). This operation should configure the object to return the proper
value from its C<ok_to_use()> method.

=item * C<ok_to_use()> A boolean that indicates whether the peer indicates
proper support for the extension. This should not be called until after
C<consume_parameters().

=back

=cut

sub new {
    my ($class, %opts) = @_;

    if ($opts{'extensions'}) {
        $opts{'_extension_tokens'} = { map { $_->token() => $_ } @{ $opts{'extensions'} } };
    }

    return bless \%opts, $class;
}

=head2 $sp_token = I<OBJ>->get_subprotocol()

Returns the negotiated subprotocol’s token (e.g., C<wamp.2.json>).

=cut

sub get_subprotocol {
    my $self = shift;

    if (!$self->{'_no_use_legacy'}) {
        die 'Must call consume_headers() first!';
    }

    return $self->{'_subprotocol'};
}

#sub get_match_extensions {
#    my $self = shift;
#
#    Call::Context::must_be_list();
#
#    return { %{ $self->{'_match_extensions'} } };
#}

=head2 I<OBJ>->consume_headers( HDR1 => VAL1, HDR2 => VAL2, .. )

The “workhorse” method of this base class. Takes in the HTTP headers
and verifies that the look as they should, setting this object’s own
internals as appropriate.

=cut

sub consume_headers {
    my ($self, @kv_pairs) = @_;

    $self->{'_no_use_legacy'} = 1;

    while ( my ($k => $v) = splice( @kv_pairs, 0, 2 ) ) {
        $self->_consume_peer_header($k => $v);
    }

    $self->_valid_headers_or_die();

    return;
}

=head2 my $hdrs_txt = I<OBJ>->to_string()

The text of the HTTP headers to send, with the 2nd trailing CR/LF
that ends the headers portion of an HTTP message.

If you use this object
to negotiate a subprotocol and/or extensions, those will be included
in the output from this method.

To append custom headers, do the following with the result of this method:

     substr($hdrs_txt, -2, 0) = '..';

=cut

sub to_string {
    my $self = shift;

    return join( CRLF(), $self->_create_header_lines(), q<>, q<> );
}

=head1 LEGACY INTERFACE

Prior to version 0.5 this module was a great deal less “helpful”:
it required callers to parse out and write WebSocket headers,
doing most of the validation manually. Version 0.5 added a generic
interface for entering in HTTP headers, which allows Net::WebSocket to
handle the parsing and creation of HTTP headers as well as subprotocol
and extension negotiation.

For now the legacy functionality is being left in; however,
it is considered DEPRECATED and will be removed eventually.

=head2 my $hdrs_txt = I<OBJ>->create_header_text()

The same output as C<to_string()> but minus the 2nd trailing
CR/LF. (This was intended to facilitate adding other headers; however,
that’s done easily enough with the newer C<to_string()>.)

=cut

sub create_header_text {
    my $self = shift;

    return join( CRLF(), $self->_create_header_lines(), q<> );
}

=head1 SEE ALSO

=over

=item * L<Net::WebSocket::Handshake::Client>

=item * L<Net::WebSocket::Handshake::Server>

=back

=cut

#----------------------------------------------------------------------

sub _get_accept {
    my ($self) = @_;

    my $key_b64 = $self->{'key'} or do {
        die Net::WebSocket::X->create('BadArg', key => $self->{'key'});
    };

    $key_b64 =~ s<\A\s+|\s+\z><>g;

    my $accept = Digest::SHA::sha1_base64( $key_b64 . _WS_MAGIC_CONSTANT() );

    #pad base64
    $accept .= '=' x (4 - (length($accept) % 4));

    return $accept;
}

#Post-legacy, move this to Client and have the Server use logic
#that allows only one.
sub _encode_subprotocols {
    my ($self) = @_;

    return ( $self->{'subprotocols'} && @{ $self->{'subprotocols'} }
        ? ( 'Sec-WebSocket-Protocol: ' . join(', ', @{ $self->{'subprotocols'} } ) )
        : ()
    );
}

sub _encode_extensions {
    my ($self) = @_;

    return if !$self->{'extensions'};

    my @handshake_xtns;
    for my $xtn ( @{ $self->{'extensions'} } ) {
        if ( $xtn->isa('Net::WebSocket::Handshake::Extension') ) {
            $self->_warn_legacy();
            push @handshake_xtns, $xtn;
        }
        elsif ( $self->_should_include_extension_in_headers($xtn) ) {
            push @handshake_xtns, $xtn->get_handshake_object();
        }
    }

    return if !@handshake_xtns;

    my ($first, @others) = @handshake_xtns;

    return 'Sec-WebSocket-Extensions: ' . $first->to_string(@others);
}

sub _warn_legacy {
    my ($self) = @_;

    if (!$self->{'_warned_legacy'}) {
        my $ref = ref $self;
        warn "You are using $ref’s legacy interface. This interface will eventually be removed from $ref entirely, so please update your application to the newer interface. (The update should simplify your code.)";

        $self->{'_warned_legacy'}++;
    }

    return;
}

sub _missing_generic_headers {
    my ($self) = @_;

    my @missing;
    push @missing, 'Connection' if !$self->{'_connection_header_ok'};
    push @missing, 'Upgrade' if !$self->{'_upgrade_header_ok'};

    return @missing;
}

sub _consume_sec_websocket_extensions_header {
    my ($self, $value) = @_;

    Module::Load::load('Net::WebSocket::Handshake::Extension');

    for my $xtn ( Net::WebSocket::Handshake::Extension->parse_string($value) ) {
        my $xtn_token = $xtn->token();
        my $xtn_handler = $self->{'_extension_tokens'}{ $xtn_token };
        if ($xtn_handler) {
            $xtn_handler->consume_parameters($xtn->parameters());

            if ($xtn_handler->ok_to_use()) {
                $self->{'_match_extensions'}{ $xtn_token } = $xtn_handler;
            }
        }
        else {
            $self->_handle_unrecognized_extension($xtn);
        }
    }

    return;
}

sub _consume_generic_header {
    my ($self, $hname, $value) = @_;

    tr<A-Z><a-z> for ($hname);

    if ($hname eq 'connection') {
        $value =~ tr<A-Z><a-z>;
        for my $t ( Net::WebSocket::HTTP::split_tokens($value) ) {
            if ($t eq 'upgrade') {
                $self->{'_connection_header_ok'} = 1;
            }
        }
    }
    elsif ($hname eq 'upgrade') {
        $value =~ tr<A-Z><a-z>;
        for my $t ( Net::WebSocket::HTTP::split_tokens($value) ) {
            if ($t eq 'websocket') {
                $self->{'_upgrade_header_ok'} = 1;
            }
        }
    }
    elsif ($hname eq 'sec-websocket-protocol') {
        for my $token ( Net::WebSocket::HTTP::split_tokens($value) ) {
            if (!defined $self->{'_match_protocol'}) {
                ($self->{'_match_protocol'}) = grep { $_ eq $token } @{ $self->{'subprotocols'} };
            }
        }
    }
    elsif ($hname eq 'sec-websocket-extensions') {
        $self->_consume_sec_websocket_extensions_header($value);
    }

    return;
}

1;
