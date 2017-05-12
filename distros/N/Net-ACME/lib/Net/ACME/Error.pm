package Net::ACME::Error;

=encoding utf-8

=head1 NAME

Net::ACME::Error - error parsing logic for ACME

=head1 SYNOPSIS

    use Net::ACME::Error;

    my $err = Net::ACME::Error->new( { type => '..', .. } );

=head1 DESCRIPTION

This simple module interfaces with ACME “error” objects,
which are described in section 5.5 of the protocol spec.
(cf. L<https://ietf-wg-acme.github.io/acme/#rfc.section.5.5>)

=head1 NOTES

ACME’s errors are basically just HTTP API problem detail documents,
which are described in more detail at L<https://tools.ietf.org/html/draft-ietf-appsawg-http-problem-03>.

=cut

use strict;
use warnings;

use parent qw( Net::ACME::AccessorBase );

#require.pm fails weirdly here.
our ( %TYPE_DESCRIPTION );

use constant _ACCESSORS => qw(
    detail
    instance
    status
    title
    type
);

BEGIN {

    #cf. https://ietf-wg-acme.github.io/acme/#errors
    %TYPE_DESCRIPTION = (
        badCSR                => 'The CSR is unacceptable (e.g., due to a short key)',
        badNonce              => 'The client sent an unacceptable anti-replay nonce',
        connection            => 'The server could not connect to the client for validation',
        dnssec                => 'The server could not validate a DNSSEC signed domain',
        caa                   => 'CAA records forbid the CA from issuing',
        malformed             => 'The request message was malformed',
        serverInternal        => 'The server experienced an internal error',
        tls                   => 'The server experienced a TLS error during validation',
        unauthorized          => 'The client lacks sufficient authorization',
        unknownHost           => 'The server could not resolve a domain name',
        rateLimited           => 'The request exceeds a rate limit',
        invalidContact        => 'The provided contact URI for a registration was invalid',
        rejectedIdentifier    => 'The server will not issue for the identifier',
        unsupportedIdentifier => 'Identifier is not supported, but may be in the future',
        agreementRequired     => 'The client must agree to terms before proceeding',
    );
}

sub type {
    my ($self) = @_;

    return $self->SUPER::type() || 'about:blank';
}

sub description {
    my ($self) = @_;

    my $type = $self->type();

    #The spec describes errors in the “urn:ietf:params:acme:error:”
    #namespace; however, Boulder/LE gives them in “urn:acme:error:”.
    #
    #This is because Boulder implements an older version of the spec:
    #https://github.com/letsencrypt/boulder/issues/1769
    if ( !( $type =~ s<\Aurn:ietf:params:acme:error:><> ) ) {
        $type =~ s<\Aurn:acme:error:><>;
    }

    return $TYPE_DESCRIPTION{$type};
}

#This might warrant expansion?
sub to_string {
    my ($self) = @_;

    my $type = $self->type();
    if ( my $desc = $self->description() ) {
        $type = sprintf "%s (%s)", $desc, $type;
    }

    my $detail = $self->detail();
    if ( defined $detail && length $detail ) {
        return sprintf "%s (%s)", $self->detail(), $type;
    }

    return $type;
}

1;
