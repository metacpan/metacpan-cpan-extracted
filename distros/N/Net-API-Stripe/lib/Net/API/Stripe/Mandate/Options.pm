##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Mandate/Options.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/08/11
## Modified 2022/08/11
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Mandate::Options;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_type { return( shift->_set_get_scalar( 'amount_type', @_ ) ); }

# checkout_session
sub custom_mandate_url { return( shift->_set_get_uri( 'custom_mandate_url', @_ ) ); }

# checkout_session
sub default_for { return( shift->_set_get_array_as_object( 'default_for', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub end_date { return( shift->_set_get_datetime( 'end_date', @_ ) ); }

sub interval { return( shift->_set_get_scalar( 'interval', @_ ) ); }

sub interval_count { return( shift->_set_get_number( 'amount', @_ ) ); }

sub interval_description { return( shift->_set_get_scalar( 'interval_description', @_ ) ); }

# checkout_session
sub payment_schedule { return( shift->_set_get_scalar( 'payment_schedule', @_ ) ); }

sub reference { return( shift->_set_get_scalar( 'reference', @_ ) ); }

sub start_date { return( shift->_set_get_datetime( 'start_date', @_ ) ); }

sub transaction_type { return( shift->_set_get_scalar( 'transaction_type', @_ ) ); }

sub supported_types { return( shift->_set_get_array_object( 'supported_types', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Mandate::Options - Stripe API

=head1 SYNOPSIS

    use Net::API::Stripe::Mandate::Options;
    my $this = Net::API::Stripe::Mandate::Options->new || 
        die( Net::API::Stripe::Mandate::Options->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head2 amount

Amount to be charged for future payments.

=head2 amount_type

One of C<fixed> or C<maximum>. If C<fixed>, the amount param refers to the exact amount to be charged in future payments. If C<maximum>, the amount charged can be up to the value passed for the amount param.

=head2 custom_mandate_url string

A URL for custom mandate text

=head2 default_for array of enum values

List of Stripe products where this mandate can be selected automatically. Returned when the Session is in setup mode.

Possible enum values

=over 4

=item * C<invoice>

Enables payments for Stripe Invoices. ‘subscription’ must also be provided.

=item * C<subscription>

Enables payments for Stripe Subscriptions. ‘invoice’ must also be provided.

=back

=head2 description

A description of the mandate or subscription that is meant to be displayed to the customer.

=head2 end_date

End date of the mandate or subscription. If not provided, the mandate will be active until canceled. If provided, end date should be after start date.

=head2 interval

Specifies payment frequency. One of C<day>, C<week>, C<month>, C<year>, or C<sporadic>.

=head2 interval_count

The number of intervals between payments. For example, C<interval=month> and C<interval_count=3> indicates one payment every three months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks). This parameter is optional when C<interval=sporadic>.

=head2 interval_description string

Description of the interval. Only required if the C<payment_schedule> parameter is C<interval> or C<combined>.

=head2 payment_schedule enum

Payment schedule for the mandate.

Possible enum values

=over 4

=item * C<interval>

Payments are initiated at a regular pre-defined interval

=item * C<sporadic>

Payments are initiated sporadically

=item * C<combined>

Payments can be initiated at a pre-defined interval or sporadically

=back

=head2 reference

Unique identifier for the mandate or subscription.

=head2 start_date

Start date of the mandate or subscription. Start date should not be lesser than yesterday.

=head2 supported_types

Specifies the type of mandates supported. Possible values are C<india>.

=head2 transaction_type

Found in L<invoice object|https://stripe.com/docs/api/invoices/object#invoice_object-payment_settings-payment_method_options-acss_debit-mandate_options-transaction_type> and in L<subscription object|https://stripe.com/docs/api/subscriptions/object#subscription_object-payment_settings-payment_method_options-acss_debit-mandate_options-transaction_type> and in L<checkout session|https://stripe.com/docs/api/checkout/sessions/object#checkout_session_object-payment_method_options-acss_debit-mandate_options-transaction_type>

Transaction type of the mandate.

Possible enum values

=over 4

=item * C<personal>

Transactions are made for personal reasons

=item * C<business>

Transactions are made for business reasons

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Payment intent, mandate_options property|https://stripe.com/docs/api/payment_intents/object#payment_intent_object-payment_method_options-card-mandate_options>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
