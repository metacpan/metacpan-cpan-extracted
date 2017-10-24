package Net::WebSocket::PMCE::deflate;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE::deflate - WebSocket’s C<permessage-deflate> extension

=head1 SYNOPSIS

See L<Net::WebSocket::PMCE::deflate::Server> or
L<Net::WebSocket::PMCE::deflate::Client> for usage examples.

=head1 DESCRIPTION

This class implements C<permessage-deflate> as defined in
L<RFC 7692|https://tools.ietf.org/html/rfc7692>.

This is a base class, not to be instantiated directly.

This class implements a L<Net::WebSocket::Handshake>-compatible
extension interface.

=head1 STATUS

This module is an ALPHA release. Changes to the API are not unlikely;
be sure to check the changelog before updating, and please report any
issues you find.

=cut

use strict;
use warnings;

use parent qw( Net::WebSocket::PMCE::deflate::Constants );

use Module::Load ();

use Net::WebSocket::Handshake::Extension ();
use Net::WebSocket::PMCE::deflate::Constants ();
use Net::WebSocket::X ();

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Returns a new instance of this class.

C<%OPTS> is:

=over

=item C<deflate_max_window_bits> - optional; the maximum number of window bits
that this endpoint will use to compress messages. See C<client_max_window_bits>
in L<RFC 7692|https://tools.ietf.org/html/rfc7692> for valid values.

=item C<inflate_max_window_bits> - optional; the number of window bits to use
to decompress messages. Valid values are the same as for
C<deflate_max_window_bits>.

=item C<deflate_no_context_takeover> - boolean; whether the compressor
will forgo context takeover. (See below.)

=item C<inflate_no_context_takeover> - boolean; whether the decompressor
can forgo context takeover.

=back

This interface uses C<deflate_*>/C<inflate_*> prefixes rather than
C<client_*>/C<server_*> as the RFC uses because the module author
has found C<deflate_*>/C<inflate_*> easier to conceptualize.

=head1 CONTEXT TAKEOVER: THE MISSING EXPLANATION

As best I can tell, the term “context takeover” is indigenous to
permessage-deflate. The term appears all over the RFC but isn’t explained
very clearly, in my opinion. Here, then, is an attempt to provide that
explanation.

As a DEFLATE compressor receives bytes of the stream, it “remembers”
common sequences of past parts of the stream in a “window” that
“slides” along with the data stream: this is the LZ77 ”sliding window”.

By default, permessage-deflate retains the previous message’s sliding
window and uses it to compress the start of the next message;
this is called “context takeover” because the new message “takes over”
the “context” (i.e., sliding window) from the previous message. Setting
one or the other peer to “no context takeover” mode, then, tells that
peer to empty out its sliding window at the end of each message. This
means that peer won’t need to retain the sliding window between messages,
which can reduce memory consumption.

In DEFLATE terms, a compressor does a SYNC flush at the end of each
message when using context takeover; otherwise the compressor does a
FULL flush.

Maybe a better term for this behavior would have been “window retention”.
Anyway, there it is.

=cut

sub new {
    my ($class, %opts) = @_;

    my @errs = $class->_get_parameter_errors(%opts);
    die "@errs" if @errs;

    return bless \%opts, $class;
}

=head2 I<OBJ>->deflate_max_window_bits()

The effective value of this setting. If unspecified or if the peer doesn’t
support this feature, the returned value will be the RFC’s default value.

=cut

sub deflate_max_window_bits {
    my ($self) = @_;

    return $self->{'deflate_max_window_bits'} || ( $self->VALID_MAX_WINDOW_BITS() )[-1];
}

=head2 I<OBJ>->inflate_max_window_bits()

The effective value of this setting. If unspecified or if the peer doesn’t
support this feature, the returned value will be the RFC’s default value.

=cut

sub inflate_max_window_bits {
    my ($self) = @_;

    return $self->{'inflate_max_window_bits'} || ( $self->VALID_MAX_WINDOW_BITS() )[-1];
}

=head2 I<OBJ>->deflate_no_context_takeover()

Whether to drop the LZ77 sliding window between messages (i.e.,
to do a full DEFLATE flush with each FIN frame).

=cut

sub deflate_no_context_takeover {
    my ($self) = @_;

    return !!$self->{'deflate_no_context_takeover'};
}

=head2 I<OBJ>->inflate_no_context_takeover()

Whether to ask the peer drop the LZ77 sliding window between messages.

=cut

sub inflate_no_context_takeover {
    my ($self) = @_;

    return !!$self->{'inflate_no_context_takeover'};
}

=head2 I<OBJ>->create_data_object()

A convenience method that returns an instance of the appropriate
subclass of L<Net::WebSocket::PMCE::deflate::Data>.

=cut

sub create_data_object {
    my ($self) = @_;

    my $class = __PACKAGE__ . '::Data::' . $self->_ENDPOINT_CLASS();
    Module::Load::load($class);

    return $class->new( %$self );
}

#----------------------------------------------------------------------

=head2 I<OBJ>->token()

As described in L<Net::WebSocket::Handshake>’s documentation.

=cut

#====== INHERITED from an undocumented base class

=head2 I<OBJ>->get_handshake_object()

As described in L<Net::WebSocket::Handshake>’s documentation.

=cut

sub get_handshake_object {
    my ($self) = @_;

    return Net::WebSocket::Handshake::Extension->new(
        $self->_create_extension_header_parts(),
    );
}

=head2 I<OBJ>->consume_parameters( KEY1 => VALUE1, .. )

As described in L<Net::WebSocket::Handshake>’s documentation. After
this function runs, you can inspect the I<OBJ> to ensure that the
configuration that the peer allows is one that your application
finds acceptable. (It likely is, but hey.)

See this module’s subclasses’ documentation for more details about
how they handle each parameter.

=cut

sub consume_parameters {
    my ($self, @params) = @_;

    my %opts = @params;

    $self->_consume_extension_options(\%opts);

    if (%opts) {
        my $token = $self->token();
        die "Unrecognized for “$token”: @params";
    }

    $self->{'_use_ok'}++;

    return;
}

=head2 I<OBJ>->ok_to_use()

As described in L<Net::WebSocket::Handshake>’s documentation.

=cut

sub ok_to_use {
    my ($self) = @_;

    return !!$self->{'_use_ok'};
}

#----------------------------------------------------------------------

# 7. .. A server MUST decline an extension negotiation offer for this
# extension if any of the following conditions are met:
sub _get_parameter_errors {
    my ($class, @params_kv) = @_;

    my %params;

    my @errors;

    while ( my ($k, $v) = splice( @params_kv, 0, 2 ) ) {

        #The negotiation (offer/response) contains multiple extension
        #parameters with the same name.
        if ( exists $params{$k} ) {
            if (defined $v) {
                push @errors, "Duplicate parameter /$k/ ($v)";
            }
            else {
                push @errors, "Duplicate parameter /$k/, no value";
            }
        }

        #The negotiation (offer/response) contains an extension parameter
        #with an invalid value.
        if ( my $cr = $class->can("_validate_$k") ) {
            push @errors, $cr->($class, $v);
        }

        #The negotiation (offer/response) contains an extension parameter
        #not defined for use in an (offer/response).
        else {
            if (defined $v) {
                push @errors, "Unknown parameter /$k/ ($v)";
            }
            else {
                push @errors, "Unknown parameter /$k/, no value";
            }
        }
    }

    return @errors;
}

#Define these as no-ops because all we care about is their truthiness.
use constant _validate_deflate_no_context_takeover => ();
use constant _validate_inflate_no_context_takeover => ();

sub _validate_deflate_max_window_bits {
    return $_[0]->__validate_max_window_bits( 'deflate', $_[1] );
}

sub _validate_inflate_max_window_bits {
    return $_[0]->__validate_max_window_bits( 'inflate', $_[1] );
}

sub __validate_no_context_takeover {
    my ($self, $endpoint, $value) = @_;

    if (defined $value) {
        return "/${endpoint}_no_context_takeover/ must not have a value.";
    }

    return;
}

sub __validate_max_window_bits {
    my ($self, $ept, $bits) = @_;

    my @VALID_MAX_WINDOW_BITS = $self->VALID_MAX_WINDOW_BITS();

    if (defined $bits) {
        return if grep { $_ eq $bits } @VALID_MAX_WINDOW_BITS;
    }

    return Net::WebSocket::X->create( 'BadArg', "${ept}_max_window_bits" => $bits, "Must be one of: [@VALID_MAX_WINDOW_BITS]" );
}

sub _create_extension_header_parts {
    my ($self) = @_;

    my @parts = $self->token();

    if (defined $self->{'deflate_max_window_bits'}) {
        push @parts, $self->_DEFLATE_MAX_WINDOW_BITS_PARAM() => $self->{'deflate_max_window_bits'};
    }

    if (defined $self->{'inflate_max_window_bits'}) {
        push @parts, $self->_INFLATE_MAX_WINDOW_BITS_PARAM() => $self->{'inflate_max_window_bits'};
    }

    if ($self->{'deflate_no_context_takeover'}) {
        push @parts, $self->_LOCAL_NO_CONTEXT_TAKEOVER_PARAM() => undef;
    }
    if ($self->{'inflate_no_context_takeover'}) {
        push @parts, $self->_PEER_NO_CONTEXT_TAKEOVER_PARAM() => undef;
    }

    return @parts;
}

#----------------------------------------------------------------------

1;

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-WebSocket>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.
