package Net::ACME2::Authorization;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::Authorization

=head1 DESCRIPTION

The ACME Authorization object.

=cut

use parent qw( Net::ACME2::AccessorBase );

use Call::Context ();
use Net::ACME2::RetryAfter ();

use Net::ACME2::Challenge ();

#Pre-load challenge classes.
use Net::ACME2::Challenge::http_01 ();
use Net::ACME2::Challenge::dns_01 ();
use Net::ACME2::Challenge::dns_account_01 ();
use Net::ACME2::Challenge::tls_alpn_01 ();

use constant _ACCESSORS => (
    'id',
    'expires',
    'status',
    'retry_after',
);

=head1 ACCESSORS

These provide text strings as defined in the ACME specification.

=over

=item * B<id()>

=item * B<status()>

=item * B<expires()>

=item * B<retry_after()>

The C<Retry-After> value from the most recent poll response,
or C<undef> if the server did not send one. Only populated
after C<poll_authorization()>.

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

=head1 OTHER METHODS

=head2 I<OBJ>->wildcard()

Returns a Perl boolean that indicates whether the authorization is
for a wildcard DNS name.

=cut

sub wildcard {
    my ($self) = @_;

    return !!$self->{'_wildcard'};
}

=head2 I<OBJ>->identifier()

The order's identifier, as a hash reference.
The content matches the ACME specification. (NB: Wildcard
authorizations do B<NOT> contain the leading C<*.> in the
C<value>.)

=cut

sub identifier {
    my ($self) = @_;

    return { %{ $self->{'_identifier'} } };
}

=head2 I<OBJ>->challenges()

The order's challenges, as a list of L<Net::ACME2::Challenge>
instances. (C<http-01> challenges will be instances of
L<Net::ACME2::Challenge::http_01>.)

Unrecognized challenge types are returned as base
L<Net::ACME2::Challenge> instances. This allows callers to inspect
their C<type()>, C<token()>, C<status()>, and C<url()> accessors
even when no dedicated subclass exists.

=cut

sub challenges {
    my ($self) = @_;

    Call::Context::must_be_list();

    my @challenges;

    for my $c ( @{ $self->{'_challenges'} } ) {
        my $specific_class = 'Net::ACME2::Challenge';

        my $module_leaf = $c->{'type'};
        $module_leaf =~ tr<-><_>;
        $specific_class .= "::$module_leaf";

        # Use the specific subclass if available, otherwise fall back
        # to the base Net::ACME2::Challenge class.
        my $class = $specific_class->can('new')
            ? $specific_class
            : 'Net::ACME2::Challenge';

        push @challenges, $class->new( %$c );
    }

    return @challenges;
}

sub update {
    my ($self, $new_hr) = @_;

    for my $name ( 'status', 'challenges' ) {
        $self->{"_$name"} = $new_hr->{$name};
    }

    return $self;
}

1;
