package Net::ACME2::Order;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::Order

=head1 DESCRIPTION

The ACME Order object.

=cut

use parent qw( Net::ACME2::AccessorBase );

use Call::Context ();
use Net::ACME2::RetryAfter ();

use constant _ACCESSORS => (
    'id',
    'status',
    'expires',
    'notBefore',
    'notAfter',
    'certificate',
    'finalize',
    'retry_after',
);

=head1 ACCESSORS

These provide text strings as defined in the ACME specification:

=over

=item * B<id()>

=item * B<status()>

=item * B<expires()>

=item * B<notBefore()>

=item * B<notAfter()>

=item * B<certificate()>

=item * B<finalize()>

=item * B<retry_after()>

The C<Retry-After> value from the most recent poll response,
or C<undef> if the server did not send one. Only populated
after C<poll_order()>.

=back

=head2 I<OBJ>->retry_after_seconds()

Parses the C<Retry-After> header value (from the most recent poll)
into an integer number of seconds. Handles both delay-seconds and
HTTP-date formats per RFC 7231.

Returns C<undef> if no C<Retry-After> was present, or C<0> if the
HTTP-date is in the past.

=cut

sub retry_after_seconds {
    my ($self) = @_;

    return Net::ACME2::RetryAfter::parse( $self->retry_after() );
}

=head2 I<OBJ>->authorizations()

The URLs for the order’s authorizations.

=cut

sub authorizations {
    my ($self) = @_;

    Call::Context::must_be_list();

    return @{ $self->{'_authorizations'} };
}

=head2 I<OBJ>->identifiers()

The order’s identifiers, as a list of hash references.
The content matches the ACME specification.

=cut

sub identifiers {
    my ($self) = @_;

    Call::Context::must_be_list();

    return map { { %$_ } } @{ $self->{'_identifiers'} };
}

#Only to be called from ACME2.pm?

sub update {
    my ($self, $new_hr) = @_;

    for my $name ( 'status', 'certificate' ) {
        $self->{"_$name"} = $new_hr->{$name};
    }

    return $self;
}

1;
