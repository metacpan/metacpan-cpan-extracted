##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Dispute/Evidence.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Issuing::Dispute::Evidence;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub canceled { return( shift->_set_get_class( 'canceled',
{
  additional_documentation     => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  canceled_at                  => { type => "datetime" },
  cancellation_policy_provided => { type => "boolean" },
  cancellation_reason          => { type => "scalar" },
  expected_at                  => { type => "datetime" },
  explanation                  => { type => "scalar" },
  product_description          => { type => "scalar" },
  product_type                 => { type => "scalar" },
  return_status                => { type => "scalar" },
  returned_at                  => { type => "datetime" },
}, @_ ) ); }

sub duplicate { return( shift->_set_get_class( 'duplicate',
{
  additional_documentation => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  card_statement           => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  cash_receipt             => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  check_image              => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  explanation              => { type => "scalar" },
  original_transaction     => { type => "scalar" },
}, @_ ) ); }

sub fraudulent { return( shift->_set_get_object( 'fraudulent', 'Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent', @_ ) ); }

sub merchandise_not_as_described { return( shift->_set_get_class( 'merchandise_not_as_described',
{
  additional_documentation => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  explanation              => { type => "scalar" },
  received_at              => { type => "datetime" },
  return_description       => { type => "scalar" },
  return_status            => { type => "scalar" },
  returned_at              => { type => "datetime" },
}, @_ ) ); }

sub not_received { return( shift->_set_get_class( 'not_received',
{
  additional_documentation => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  expected_at              => { type => "datetime" },
  explanation              => { type => "scalar" },
  product_description      => { type => "scalar" },
  product_type             => { type => "scalar" },
}, @_ ) ); }

sub other { return( shift->_set_get_object( 'other', 'Net::API::Stripe::Issuing::Dispute::Evidence::Other', @_ ) ); }

sub reason { return( shift->_set_get_scalar( 'reason', @_ ) ); }

sub service_not_as_described { return( shift->_set_get_class( 'service_not_as_described',
{
  additional_documentation => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
  canceled_at => { type => "datetime" },
  cancellation_reason => { type => "scalar" },
  explanation => { type => "scalar" },
  received_at => { type => "datetime" },
}, @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Dispute::Evidence - A Stripe Issued Card Dispute Evidence Object

=head1 SYNOPSIS

    my $ev = $stripe->issuing_dispute->evidence({
        fraudulent => 
        {
            dispute_explanation => 'Service not provided',
            uncategorized_file => $file_object,
        },
        other =>
        {
            dispute_explanation => 'Service was not provided',
            uncategorized_file => $file_object,
        },
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Evidence related to the dispute. This hash will contain exactly one non-null value, containing an evidence object that matches its reason

This is instantiated by method B<evidence> in module L<Net::API::Stripe::Issuing::Dispute>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Dispute::Evidence> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 canceled hash

Evidence provided when C<reason> is 'canceled'.

It has the following properties:

=over 4

=item I<additional_documentation> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Additional documentation supporting the dispute.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<canceled_at> timestamp

Date when order was canceled.

=item I<cancellation_policy_provided> boolean

Whether the cardholder was provided with a cancellation policy.

=item I<cancellation_reason> string

Reason for canceling the order.

=item I<expected_at> timestamp

Date when the cardholder expected to receive the product.

=item I<explanation> string

Explanation of why the cardholder is disputing this transaction.

=item I<product_description> string

Description of the merchandise or service that was purchased.

=item I<product_type> string

Whether the product was a merchandise or service.

=item I<return_status> string

Result of cardholder's attempt to return the product.

=item I<returned_at> timestamp

Date when the product was returned or attempted to be returned.

=back

=head2 duplicate hash

Evidence provided when `reason` is 'duplicate'.'

It has the following properties:

=over 4

=item I<additional_documentation> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Additional documentation supporting the dispute.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<card_statement> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Copy of the card statement showing that the product had already been paid for.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<cash_receipt> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Copy of the receipt showing that the product had been paid for in cash.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<check_image> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Image of the front and back of the check that was used to pay for the product.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<explanation> string

Explanation of why the cardholder is disputing this transaction.

=item I<original_transaction> string

Transaction (e.g., ipi_...) that the disputed transaction is a duplicate of. Of the two or more transactions that are copies of each other, this is original undisputed one.

=back

=head2 fraudulent hash

Evidence to support a fraudulent dispute. This will only be present if your dispute’s reason is fraudulent.

This is a L<Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent> object.

=head2 merchandise_not_as_described hash

Evidence provided when C<reason> is 'merchandise_not_as_described'.'

It has the following properties:

=over 4

=item I<additional_documentation> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Additional documentation supporting the dispute.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<explanation> string

Explanation of why the cardholder is disputing this transaction.

=item I<received_at> timestamp

Date when the product was received.

=item I<return_description> string

Description of the cardholder's attempt to return the product.

=item I<return_status> string

Result of cardholder's attempt to return the product.

=item I<returned_at> timestamp

Date when the product was returned or attempted to be returned.

=back

=head2 not_received hash

Evidence provided when C<reason> is 'not_received'.

It has the following properties:

=over 4

=item I<additional_documentation> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Additional documentation supporting the dispute.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<expected_at> timestamp

Date when the cardholder expected to receive the product.

=item I<explanation> string

Explanation of why the cardholder is disputing this transaction.

=item I<product_description> string

Description of the merchandise or service that was purchased.

=item I<product_type> string

Whether the product was a merchandise or service.

=back

=head2 other hash

Evidence to support an uncategorized dispute. This will only be present if your dispute’s reason is other.

This is a L<Net::API::Stripe::Issuing::Dispute::Evidence::Other> object.

=head2 reason string

The reason for filing the dispute. Its value will match the field containing the evidence.

=head2 service_not_as_described hash

Evidence provided when C<reason> is 'service_not_as_described'.

It has the following properties:

=over 4

=item I<additional_documentation> string expandable

(ID of a L<file upload|https://stripe.com/docs/guides/file-upload>) Additional documentation supporting the dispute.

When expanded this is an L<Net::API::Stripe::File> object.

=item I<canceled_at> timestamp

Date when order was canceled.

=item I<cancellation_reason> string

Reason for canceling the order.

=item I<explanation> string

Explanation of why the cardholder is disputing this transaction.

=item I<received_at> timestamp

Date when the product was received.

=back

=head1 API SAMPLE

    {
      "id": "idp_fake123456789",
      "object": "issuing.dispute",
      "amount": 100,
      "created": 1571480456,
      "currency": "usd",
      "disputed_transaction": "ipi_fake123456789",
      "evidence": {
        "fraudulent": {
          "dispute_explanation": "Fraud; card reported lost on 10/19/2019",
          "uncategorized_file": null
        },
        "other": null
      },
      "livemode": false,
      "metadata": {},
      "reason": "fraudulent",
      "status": "under_review"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/disputes>, L<https://stripe.com/docs/issuing/disputes>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
