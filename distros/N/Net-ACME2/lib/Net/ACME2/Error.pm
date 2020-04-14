package Net::ACME2::Error;

=encoding utf-8

=head1 NAME

Net::ACME2::Error - error parsing logic for ACME

=head1 SYNOPSIS

    use Net::ACME2::Error;

    my $err = Net::ACME2::Error->new( { type => '..', .. } );

=head1 DESCRIPTION

This simple module interfaces with ACME2 “error” objects,
which are described in the ACME protocol specification.

=head1 NOTES

ACME’s errors are basically just HTTP API problem detail documents,
which are described in more detail at L<RFC 7807|https://tools.ietf.org/html/rfc7807>.

=cut

use strict;
use warnings;

use parent qw( Net::ACME2::AccessorBase );

use Call::Context ();

my $URN_PREFIX = 'urn:ietf:params:acme:error:';

use constant _ACCESSORS => qw(
    detail
    instance
    status
    title
    type
);

#cf. https://ietf-wg-acme.github.io/acme/#errors
use constant _TYPE_DESCRIPTION => {
    badCSR                => 'The CSR is unacceptable (e.g., due to a short key)',
    badNonce              => 'The client sent an unacceptable anti-replay nonce',
    badSignatureAlgorithm => 'The JWS was signed with an algorithm the server does not support',
    invalidContact        => 'A contact URL for an account was invalid',
    unsupportedContact        => 'A contact URL for an account used an unsupported protocol scheme',
    accountDoesNotExist   => 'The request specified an account that does not exist',
    malformed             => 'The request message was malformed',
    rateLimited           => 'The request exceeds a rate limit',
    rejectedIdentifier    => 'The server will not issue for the identifier',
    serverInternal        => 'The server experienced an internal error',
    unauthorized          => 'The client lacks sufficient authorization',
    unsupportedIdentifier => 'Identifier is not supported, but may be in the future',
    userActionRequired => 'Visit the “instance” URL and take actions specified there',
    badRevocationReason => 'The revocation reason provided is not allowed by the server',
    dns => 'There was a problem with a DNS query',

    connection            => 'The server could not connect to a validation target',
    dnssec                => 'The server could not validate a DNSSEC signed domain',
    caa                   => 'CAA records forbid the CA from issuing',
    tls                   => 'The server received a TLS error during validation',
    incorrectResponse     => 'Response received didn’t match the challenge’s requirements',
};

=head1 ACCESSORS

=over

=item * C<detail>

=item * C<instance>

=item * C<status>

=item * C<title>

=item * C<type> - defaults to C<about:blank>

=item * C<description> - text description of the C<type>

=item * C<subproblems> - list of subproblem objects

=item * C<to_string> - human-readable description of the error
(including subproblems)

=back

=cut

sub type {
    my ($self) = @_;

    return $self->SUPER::type() || 'about:blank';
}

sub description {
    my ($self) = @_;

    my $type = $self->type();

    $type =~ s<\A$URN_PREFIX><>;

    return _TYPE_DESCRIPTION()->{$type};
}

sub subproblems {
    my ($self) = @_;

    Call::Context::must_be_list();

    my $subs_ar = $self->{'_subproblems'} or return;

    return map { Net::ACME2::Error::Subproblem->new(%$_) } @$subs_ar;
}

sub to_string {
    my ($self) = @_;

    my $str = join( q< >, grep { defined } $self->status(), $self->type() );

    for my $attribute ( qw( title description detail instance ) ) {
        my $value = $self->$attribute();
        if ( defined $value && length $value ) {
            $str .= " ($value)";
        }
    }

    my @subs = $self->subproblems();
    if (@subs) {
        $str .= ' (' . join(', ', map { $_->to_string() } @subs) . ')';
    }

    return $str;
}

#----------------------------------------------------------------------

package Net::ACME2::Error::Subproblem;

use parent qw( Net::ACME2::Error );

use constant _ACCESSORS => (
    __PACKAGE__->SUPER::_ACCESSORS(),
    'identifier',
);

sub to_string {
    my ($self) = @_;

    my $identifier_str = join('/', @{ $self->identifier() }{'type', 'value'});

    return "$identifier_str: " . $self->SUPER::to_string();
}

1;
