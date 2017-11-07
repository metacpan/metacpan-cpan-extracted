package Net::WebSocket::Handshake::Client;

=encoding utf-8

=head1 NAME

Net::WebSocket::Handshake::Client

=head1 SYNOPSIS

    my $hsk = Net::WebSocket::Handshake::Client->new(

        #required
        uri => 'ws://haha.test',

        #optional, to imitate a web client
        origin => ..,

        #optional, base 64 .. auto-created if not given
        key => '..',

        #optional
        subprotocols => [ 'echo', 'haha' ],

        #optional
        extensions => \@extension_objects,
    );

    print $hsk->to_string();

    $hsk->consume_headers( NAME1 => VALUE1, .. );

=head1 DESCRIPTION

This class implements WebSocket handshake logic for a client.
It handles the basics of handshaking and, optionally, subprotocol
and extension negotiation.

It is a subclass of L<Net::WebSocket::Handshake>.

=cut

use strict;
use warnings;

use parent qw( Net::WebSocket::Handshake );

use URI::Split ();

use Net::WebSocket::Constants ();
use Net::WebSocket::X ();

use constant SCHEMAS => (
    'ws', 'wss',
    'http', 'https',
);

=head1 METHODS

=head2 I<OBJ>->new( %OPTS )

Returns an instance of the class; %OPTS includes the options from
L<Net::WebSocket::Handshake> as well as:

=over

=item * C<uri> - (required) The full URI you’re connecting to.

=item * C<origin> - (optional) The HTTP Origin header’s value. Useful
for imitating a web browser.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    if (length $opts{'uri'}) {
        @opts{ 'uri_schema', 'uri_auth', 'uri_path', 'uri_query' } = URI::Split::uri_split($opts{'uri'});
    }

    if (!$opts{'uri_schema'} || !grep { $_ eq $opts{'uri_schema'} } SCHEMAS()) {
        die Net::WebSocket::X->create('BadArg', uri => $opts{'uri'});
    }

    if (!length $opts{'uri_auth'}) {
        die Net::WebSocket::X->create('BadArg', uri => $opts{'uri'});
    }

    @opts{ 'uri_host', 'uri_port' } = split m<:>, $opts{'uri_auth'};

    $opts{'key'} ||= _create_key();

    return $class->SUPER::new(%opts);
}

=head2 I<OBJ>->valid_status_or_die( CODE, REASON )

Throws an exception if the given CODE isn’t the HTTP status code (101)
that WebSocket requires in response to all requests. (REASON is included
with the exception on error; otherwise it’s unused.)

You only need this if if you’re not using a request-parsing interface
that’s compatible with L<HTTP::Response>; otherwise,
L<Net::WebSocket::HTTP_R>’s C<handshake_consume_response()> function
will do this (and other niceties) for you.

=cut

sub valid_status_or_die {
    my ($self, $code, $reason) = @_;

    if ($code ne Net::WebSocket::Constants::REQUIRED_HTTP_STATUS()) {
        die Net::WebSocket::X->create('BadHTTPStatus', $code, $reason);
    }

    return;
}

#Shouldn’t be needed?
sub get_key {
    my ($self) = @_;

    return $self->{'key'};
}

#----------------------------------------------------------------------
#Legacy:

=head1 LEGACY INTERFACE: SYNOPSIS

    my $hsk = Net::WebSocket::Handshake::Client->new(

        #..same as the newer interface, except:

        #optional
        extensions => \@extension_objects,
    );

    print $hsk->create_header_text() . "\x0d\x0a";

    #...Parse the response’s headers yourself...

    #Validates the value of the “Sec-WebSocket-Accept” header;
    #throws Net::WebSocket::X::BadAccept if not.
    $hsk->validate_accept_or_die($accept_value);

=cut

sub validate_accept_or_die {
    my ($self, $received) = @_;

    my $should_be = $self->_get_accept();

    return if $received eq $should_be;

    die Net::WebSocket::X->create('BadAccept', $should_be, $received );
}

#----------------------------------------------------------------------

sub _create_header_lines {
    my ($self) = @_;

    my $path = $self->{'uri_path'};

    if (!defined $path || !length $path) {
        $path = '/';
    }

    if (defined $self->{'uri_query'} && length $self->{'uri_query'}) {
        $path .= "?$self->{'uri_query'}";
    }

    return (
        "GET $path HTTP/1.1",
        "Host: $self->{'uri_host'}",

        #For now let’s assume no one wants any other Upgrade:
        #or Connection: values than the ones WebSocket requires.
        'Upgrade: websocket',
        'Connection: Upgrade',

        "Sec-WebSocket-Key: $self->{'key'}",
        'Sec-WebSocket-Version: ' . Net::WebSocket::Constants::PROTOCOL_VERSION(),

        $self->_encode_extensions(),

        $self->_encode_subprotocols(),

        ( $self->{'origin'} ? "Origin: $self->{'origin'}" : () ),
    );
}

sub _valid_headers_or_die {
    my ($self) = @_;

    my @needed = $self->_missing_generic_headers();
    push @needed, 'Sec-WebSocket-Accept' if !$self->{'_accept_header_ok'};

    if (@needed) {
        die Net::WebSocket::X->create('MissingHeaders', @needed);
    }

    return;
}

sub _consume_peer_header {
    my ($self, $name => $value) = @_;

    my $orig_name = $name;

    $name =~ tr<A-Z><a-z>;  #case insensitivity

    for my $hdr_part ( qw( accept protocol extensions ) ) {
        if ($name eq "sec-websocket-$hdr_part") {
            if ( exists $self->{"_got_$name"} ) {
                die Net::WebSocket::X->create('DuplicateHeader', $orig_name, $self->{"_got_$name"}, $value);
            }

            $self->{"_got_$name"} = $value;
        }
    }

    if ($name eq 'sec-websocket-accept') {
        $self->validate_accept_or_die($value);
        $self->{'_accept_header_ok'} = 1;
    }
    elsif ($name eq 'sec-websocket-protocol') {
        if (!grep { $_ eq $value } @{ $self->{'subprotocols'} }) {
            die Net::WebSocket::X->create('UnknownSubprotocol', $value);
        }

        $self->{'_subprotocol'} = $value;
    }
    else {
        $self->_consume_generic_header($name => $value);
    }

    return;
}

sub _handle_unrecognized_extension {
    my ($self, $xtn_obj) = @_;

    die Net::WebSocket::X->create('UnknownExtension', $xtn_obj->to_string());
}


sub _create_key {
    Module::Load::load('MIME::Base64') if !MIME::Base64->can('encode');

    #NB: Not cryptographically secure, but it should be good enough
    #for the purpose of a nonce.
    my $sixteen_bytes = pack 'S8', map { rand 65536 } 1 .. 8;

    my $b64 = MIME::Base64::encode_base64($sixteen_bytes);
    chomp $b64;

    return $b64;
}

#Send all extensions to the server in the request.
use constant _should_include_extension_in_headers => 1;

1;
