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

use Net::ACME2::Challenge ();
use Net::ACME2::Challenge::http_01 ();

use constant _ACCESSORS => (
    'id',
    'expires',
    'status',
);

=head1 ACCESSORS

These provide text strings as defined in the ACME specification.

=over

=item * B<id()>

=item * B<status()>

=item * B<expires()>

=back

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

The order’s identifier, as a hash reference.
The content matches the ACME specification. (NB: Wildcard
authorizations do B<NOT> contain the leading C<*.> in the
C<value>.)

=cut

sub identifier {
    my ($self) = @_;

    return { %{ $self->{'_identifier'} } };
}

=head2 I<OBJ>->challenges()

The order’s challenges, as a list of L<Net::ACME2::Challenge>
instances. (C<http-01> challenges will be instances of
L<Net::ACME2::Challenge::http_01>.)

=cut

sub challenges {
    my ($self) = @_;

    Call::Context::must_be_list();

    my @challenges;

    for my $c ( @{ $self->{'_challenges'} } ) {
        my $class = 'Net::ACME2::Challenge';

        if ($c->{'type'} eq 'http-01') {
            $class .= '::http_01';
        }

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
