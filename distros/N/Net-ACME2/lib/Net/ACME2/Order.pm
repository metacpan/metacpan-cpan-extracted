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

use constant _ACCESSORS => (
    'id',
    'status',
    'expires',
    'notBefore',
    'notAfter',
    'certificate',
    'finalize',
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

=back

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
