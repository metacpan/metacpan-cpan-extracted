use strict;
use warnings;

package Net::FreshBooks::API::Recurring::AutoBill::Card;
$Net::FreshBooks::API::Recurring::AutoBill::Card::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

use Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration;

has 'expiration' => (
    is         => 'rw',
    lazy_build => 1,
    handles    => [ 'month', 'year' ],
);

has 'name' => ( is => 'rw', );

has 'number' => ( is => 'rw', );

sub node_name { return 'card' }

sub _fields {
    return {
        number     => { is => 'rw' },
        name       => { is => 'rw' },
        expiration => {
            is => 'rw',
            made_of =>
                'Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration',
            presented_as => 'object',
        },
    };
}

# make sure unitialized objects don't make the cut
sub _validates {

    my $self = shift;

    return ( $self->name && $self->number );

}

sub _build_expiration {

    my $self = shift;
    return Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration->new;
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: FreshBooks Autobill Credit Card access

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Recurring::AutoBill::Card - FreshBooks Autobill Credit Card access

=head1 VERSION

version 0.24

=head2 expiration

Returns an Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration object

=head2 name

Cardholder name

=head2 number

Card number, eg '4111 1111 1111 1111'. Can include spaces, hyphens and other
punctuation marks.

=head1 CONVENIENCE METHODS

=head2 month

The card's 2 digit expiration month. This is a shortcut to the
Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration object.

    $recurring->autobill->card->month;
    
    # is the same as
    $recurring->autobill->card->expiration->month;

=head2 year

The card's 4 digit expiration year. This is a shortcut to the
Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration object.

    $recurring->autobill->card->year;
    
    # is the same as
    $recurring->autobill->card->expiration->year;

=head1 INTERNAL METHODS

=head2 node_name

Used internally for XML parsing

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
