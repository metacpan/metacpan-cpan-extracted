package Net::ACME2::Challenge;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge

=head1 DESCRIPTION

The ACME Challenge object.

You probably won’t instantiate these directly; they’re created automatically
as part of L<Net::ACME2::Authorization> instantiation.

Known challenge types (e.g., C<http-01>, C<dns-01>) are returned as
specific subclasses. Unrecognized challenge types are returned as
instances of this base class, giving access to the standard accessors
(C<type()>, C<token()>, C<status()>, C<url()>) for any challenge a CA
may offer.

=cut

use parent qw( Net::ACME2::AccessorBase );

use Net::ACME2::Error ();

use constant _ACCESSORS => (
    'url',
    'type',
    'status',
    'validated',
    'token',
);

=head1 ACCESSORS

These provide text strings as defined in the ACME specification.

=over

=item * B<url()>

=item * B<type()>

=item * B<token()>

=item * B<status()>

=item * B<validated()>

=back

An C<error()> accessor is also provided, which returns the error object
as a L<Net::ACME2::Error> instance (or undef if there is no error).

=cut

sub error {
    my ($self) = @_;

    return $self->{'_error'} && do {
        my $obj = Net::ACME2::Error->new( %{ $self->{'_error'} } );

        # Do this to retain backward compatibility with pre-0.28 callers.
        @{$obj}{ keys %{ $self->{'_error'} } } = values %{ $self->{'_error'} };

        $obj;
    };
}

1;
