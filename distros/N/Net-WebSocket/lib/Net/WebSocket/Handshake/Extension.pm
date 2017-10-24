package Net::WebSocket::Handshake::Extension;

use strict;
use warnings;

use Call::Context ();

#We use this because it’s light; there seems little reason why
#we’d want to use anything else?
use HTTP::Headers::Util ();

=encoding utf-8

=head1 NAME

Net::WebSocket::Handshake::Extension - WebSocket extension handshake

=head1 SYNOPSIS

    #Returns a list of instances of this class
    my @exts = Net::WebSocket::Handshake::Extension->parse_string(
        $value_of_sec_websocket_extensions
    );

    my $ext = Net::WebSocket::Handshake::Extension->new(
        'extension-name',
        param1 => 'value1',
        #...
    );

    my $name = $ext->token();   #e.g., 'extension-name'

    my @params = $ext->parameters();

    #@others is an array of instances of this class
    my $str = $ext->to_string(@others);

=head1 DESCRIPTION

This module handles the handshake component of WebSocket extensions:
specifically, it translates between an extension name and parameters
as an object and as actually represented in the values of HTTP headers.

It’s flexible enough that you can determine how you want extensions
divided among multiple C<Sec-WebSocket-Extensions> headers.

Note that a server, as per the protocol specification, “MUST NOT”
include more than one C<Sec-WebSocket-Extensions> header in its
handshake response.

=head1 METHODS

=head2 @objects = I<CLASS>->parse_string( HEADER_VALUE )

Parses the value of the C<Sec-WebSocket-Extensions> header (i.e., HEADER_VALUE)
into one or more instances of this class.

=cut

sub parse_string {
    my ($class, $str) = @_;

    Call::Context::must_be_list();

    my @pieces = HTTP::Headers::Util::split_header_words($str);
    splice(@$_, 1, 1) for @pieces;

    return map { $class->new(@$_) } @pieces;
}

=head2 I<CLASS>->new( NAME, PARAMS_KV )

Returns an instance of the class, with NAME as the C<token()> value and
PARAMS_KV as C<parameters()>. Probably less useful than C<parse_string()>.

=cut

sub new {
    my ($class, @name_and_params) = @_;

    return bless \@name_and_params, $class;
}

=head2 I<OBJ>->token()

Returns the token as given in the C<Sec-WebSocket-Extensions> header.

=cut

sub token { return $_[0][0] }

=head2 %params = I<OBJ>->parameters()

Returns the parameters as given in the C<Sec-WebSocket-Extensions> header.
The parameters are a list of key/value pairs, suitable for representation
as a hash. Parameters that have no value (e.g., the C<permessage-deflate>
extension’s C<client_no_context_takeover> parameter) are given undef as a
Perl value.

=cut

sub parameters {
    Call::Context::must_be_list();
    return @{ $_[0] }[ 1 .. $#{ $_[0] } ];
}

=head2 I<OBJ>->to_string( OTHER_EXTENSIONS )

Returns a string that represents the extension (and any others) as a
C<Sec-WebSocket-Extensions> header value. Other extensions are to be given
as instances of this class.

=cut

sub to_string {
    my ($self, @others) = @_;

    return HTTP::Headers::Util::join_header_words(
        ( map { $_->_to_arrayref() } $self, @others ),
    );
}

#----------------------------------------------------------------------

sub _to_arrayref {
    return [ $_[0][0] => undef, @{ $_[0] }[ 1 .. $#{ $_[0] } ] ];
}

1;
