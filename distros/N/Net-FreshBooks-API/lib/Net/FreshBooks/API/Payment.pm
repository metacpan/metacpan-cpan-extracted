use strict;
use warnings;

package Net::FreshBooks::API::Payment;
$Net::FreshBooks::API::Payment::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';
with 'Net::FreshBooks::API::Role::CRUD';

use Net::FreshBooks::API::Links;

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub _fields {
    return {
        payment_id    => { is => 'ro' },
        client_id     => { is => 'rw' },
        invoice_id    => { is => 'rw' },
        date          => { is => 'rw' },
        amount        => { is => 'rw' },
        currency_code => { is => 'rw' },
        type          => { is => 'rw' },
        notes         => { is => 'rw' },
        updated       => { is => 'ro' },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: FreshBooks Payment access

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Payment - FreshBooks Payment access

=head1 VERSION

version 0.24

=head1 SYNOPSIS

    my $fb = Net::FreshBooks::API->new({ ... });
    my $payment = $fb->payment;

=head2 create

Create a new payment in the FreshBooks system

    my $payment = $fb->payment->create({...});

=head2 delete

    my $payment = $fb->payment->get({ payment_id => $payment_id });
    $payment->delete;

=head2 get

    my $payment = $fb->payment->get({ payment_id => $payment_id });

=head2 update

    $payment->notes('Payment Refunded.');
    $payment->update;

    # or more directly
    $client->update( { notes => 'Payment refunded' } );

=head2 list

Returns a L<Net::FreshBooks::API::Iterator> object.

    my $payments = $fb->payment->list;
    while ( my $payment = $payments->next ) {
        print $payment->payment_id, "\n";
    }

=head1 DESCRIPTION

This class gives you object to FreshBooks payment information.
L<Net::FreshBooks::API> will construct this object for you.

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
