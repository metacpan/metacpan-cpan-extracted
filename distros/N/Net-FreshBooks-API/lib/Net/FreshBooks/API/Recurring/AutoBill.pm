use strict;
use warnings;

package Net::FreshBooks::API::Recurring::AutoBill;
$Net::FreshBooks::API::Recurring::AutoBill::VERSION = '0.24';
use Net::FreshBooks::API::Recurring::AutoBill::Card;

use Moose;
extends 'Net::FreshBooks::API::Base';

has 'gateway_name' => ( is => 'rw', );

has 'card' => (
    is  => 'rw',
    isa => 'Net::FreshBooks::API::Recurring::AutoBill::Card',
    default =>
        sub { return Net::FreshBooks::API::Recurring::AutoBill::Card->new },
);

sub node_name { return 'autobill' }

# ensure only fully initialized objects make the cut

# Due to the way this module works, when recurring items are updated, all
# mutable fields already in the object are passed back to FreshBooks. This
# causes a problem with the following scenario:
#
# 1) A recurring item is fetched from FreshBooks
# 2) The card number field returned by FreshBooks will look something like **** **** **** 1111
# 3) When an update request is sent to FreshBooks, the request will fail on an invalid number
#
# So, to protect the user from this condition, if a card number in the
# recurring item contains a '*', the AutoBill fields won't be passed for
# updating. In most cases this is probably the behaviour which you want as it
# prevents you from having to set autobill to an empty string on the update of
# any recurring item.

# this method returns true if any one of the autobill params is non-empty,
# provided that the card number is not the one returned to us by FreshBooks

sub _validates {

    my $self = shift;

    return 0 if $self->card->number && $self->card->number =~ m{\*};

    return 1
        if ( $self->gateway_name
        || $self->card->name
        || $self->card->month
        || $self->card->year );

}

sub _fields {
    return {
        gateway_name => { is => 'rw' },
        card         => {
            is           => 'rw',
            made_of      => 'Net::FreshBooks::API::Recurring::AutoBill::Card',
            presented_as => 'object',
        },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: Adds AutoBill support to FreshBooks Recurring Items

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Recurring::AutoBill - Adds AutoBill support to FreshBooks Recurring Items

=head1 VERSION

version 0.24

=head1 SYNOPSIS

Autobill objects can be created via a recurring item:

    my $autobill = $recurring_item->autobill;

If you want options, you can also do it the hard way:

    my $autobill = Net::FreshBooks::API::Recurring::AutoBill->new;
    ... set autobill params ...
    $recurring_item->autobill( $autobill );

If you like lots of arrows:

    $recurring_item->autobill->card->expiration->month(12);

In summary:

    my $autobill = $recurring_item->autobill;
    $autobill->gateway_name('PayPal Payflow Pro');
    $autobill->card->name('Tim Toady');
    $autobill->card->number('4111 1111 1111 1111');
    $autobill->card->expiration->month(12);
    $autobill->card->expiration->year(2015);
    
    $recurring_item->create;

=head2 gateway name

Case insensitive gateway name from Gateway list (Must be auto-bill enabled).

    $autobill->gateway_name('PayPal Payflow Pro');

=head2 card

Returns a Net::FreshBooks::API::Recurring::AutoBill::Card object

    my $cardholder_name = $autobill->card->name;
    
    # This syntax follows the format of the XML request

    $autobill->card->name('Tim Toady');
    $autobill->card->number('4111 1111 1111 1111');
    $autobill->card->expiration->month(12);
    $autobill->card->expiration->year(2015);
    
    # This alternate syntax is less verbose
    $autobill->card->name('Tim Toady');
    $autobill->card->number('4111 1111 1111 1111');
    $autobill->card->month(12);
    $autobill->card->year(2015);

=head1 CAVEATS

To delete a recurring item's autobill status, autobill should explicitly be
set to an empty string. This will send an empty autobill element to
FreshBooks, which is the correct syntax for deleting existing autobill info.
This only makes sense in the context of an update.  If you are creating a new
recurring item without autobill, just don't touch the AutoBill object and it
will "do the right thing".

    $recurring_item->autobill( '' ); # delete an autobill profile
    $recurring_item->update;

If you are updating autobill for a recurring item, you must update the credit
card number, or the request will fail. This is because, while FreshBooks
requires all autobill elements to be present, FreshBooks returns only the last
4 digits of the card number when the item is fetched.  So, the only way to
establish the actual card number is for you to provide it.

    my $item = $freshbooks->recurring_item->get({ recurring_id => $id });
    $item->autobill->card->number( $new_number );
    $item->update;

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
