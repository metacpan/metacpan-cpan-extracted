package Nitesi::Transaction;

use Moo;
use Sub::Quote;

=head1 NAME

Nitesi::Transaction - Transaction class for Nitesi Shop Machine

=head1 ATTRIBUTES

=head2 code

Transaction code.

=cut

has code => (
    is => 'rw',
);

=head2 subtotal

Transaction subtotal.

=cut

has subtotal => (
    is => 'rw',
);

=head2 shipping

Shipping cost.

=cut

has shipping => (
    is => 'rw',
);

=head2 salestax

Salestax included in transaction.

=cut

has salestax => (
    is => 'rw',
);

=head2 total_cost

Transaction total cost.

=cut

has total_cost => (
    is => 'rw',
);

=head2 weight

Total weight of all goods in this transaction.

=cut

has weight => (
    is => 'rw',
);

=head2 uid

User identifier of customer.

=cut

has uid => (
    is => 'rw',
);

=head2 email

Email address of customer.

=cut

has email => (
    is => 'rw',
);

=head2 lname

Last name of customer.

=cut

has lname => (
    is => 'rw',
);

=head2 fname

First name of customer.

=cut

has fname => (
    is => 'rw',
);

=head2 order_date

Date of order.

=cut

has order_date => (
    is => 'rw',
);

=head2 update_date

Date of last update.

=cut

has update_date => (
    is => 'rw',
);

=head2 status

Transaction status.

=cut

has status => (
    is => 'rw',
);

=head2 shipping_method

Shipping method for transaction.

=cut

has shipping_method => (
    is => 'rw',
);

=head2 shipping_description

Shipping description for transaction.

=cut

has shipping_description => (
    is => 'rw',
);

=head2 shipping_tax_rate

Tax rate used for shipping.

=cut

has shipping_tax_rate => (
    is => 'rw',
);

=head2 payment_method

Payment method for this transaction.

=cut

has payment_method => (
    is => 'rw',
);

=head2 payment_id

Payment transaction id.

=cut

has payment_id => (
    is => 'rw',
);

=head2 aid_shipping

Shipping address identifier.

=cut

has aid_shipping => (
    is => 'rw',
);

=head2 aid_billing

Billing address identifier.

=cut

has aid_billing => (
    is => 'rw',
);

=head1 METHODS

=head2 api_attributes

API attributes for transaction class.

=cut

has api_attributes => (
    is => 'rw',
);

=head2 api_info

Returns API information for transaction object.

=cut

sub api_info {
    my $self = shift;

    return {base => '__PACKAGE__',
            table => 'transactions',
            key => 'code',
            attributes => $self->api_attributes,
    };
};

1;
