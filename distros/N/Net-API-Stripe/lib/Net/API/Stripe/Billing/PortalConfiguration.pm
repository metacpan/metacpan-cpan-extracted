##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Plan/PortalConfiguration.pm
## Version v0.2.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::PortalConfiguration;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub business_profile { return( shift->_set_get_class( 'business_profile',
{
    headline => { type => 'scalar' },
    privacy_policy_url => { type => 'uri' },
    terms_of_service_url => { type => 'uri' },
}, @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub default_return_url { return( shift->_set_get_uri( 'default_return_url', @_ ) ); }

sub features { return( shift->_set_get_class( 'features',
{
  customer_update       => {
                             definition => {
                               allowed_updates => { type => "array" },
                               enabled => { type => "boolean" },
                             },
                             type => "class",
                           },
  invoice_history       => {
                             package => "Net::API::Stripe::Payment::Installment",
                             type => "object",
                           },
  payment_method_update => {
                             package => "Net::API::Stripe::Payment::Installment",
                             type => "object",
                           },
  subscription_cancel   => {
                             definition => {
                               cancellation_reason => {
                                 definition => { enabled => { type => "boolean" }, options => { type => "array" } },
                                 type => "class",
                               },
                               enabled => { type => "boolean" },
                               mode => { type => "scalar" },
                               proration_behavior => { type => "scalar" },
                             },
                             type => "class",
                           },
  subscription_pause    => {
                             package => "Net::API::Stripe::Payment::Installment",
                             type => "object",
                           },
  subscription_update   => {
                             definition => {
                               default_allowed_updates => { type => "array" },
                               enabled => { type => "boolean" },
                               products => {
                                 definition => { prices => { type => "array" }, product => { type => "scalar" } },
                                 type => "class_array",
                               },
                               proration_behavior => { type => "scalar" },
                             },
                             type => "class",
                           },
}, @_ ) ); }

sub is_default { return( shift->_set_get_boolean( 'is_default', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub login_page { return( shift->_set_get_class( 'login_page',
{ enabled => { type => "boolean" }, url => { type => "uri" } }, @_ ) ); }

sub metadata { return( shift->_set_get_hash_as_mix_object( 'metadata', @_ ) ); }

sub updated { return( shift->_set_get_datetime( 'updated', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::PortalConfiguration - The portal configuration object

=head1 SYNOPSIS

    my $portal = $stripe->portal_conffiguration({
        created => 'now',
        active => $stripe->true,
        application => 'acct_fake123456789',
        business_profile =>
        {
            headline = q{Welcome to Example Business payment portal},
            privacy_policy_url => q{https://example.com/privacy-policy/},
            terms_of_service_url => q{https://example.com/tos/},
        },
        default_return_url => 'https://example.com/ec/df63685a-6cd2-4c5d-9d4c-81b417646a58',
        features =>
        {
            customer_update =>
            {
                allowed_updates => [qw( email address shipping phone tax_id )],
                enabled => 1,
            },
            invoice_history =>
            {
                enabled => 1,
            },
            payment_method_update =>
            {
                enabled => 1,
            },
            subscription_cancel =>
            {
                cancellation_reason =>
                {
                    enabled => 1,
                    options => [qw( too_expensive missing_features switched_service unused customer_service too_complex low_quality other )],
                },
                enabled => 1,
                mode => [qw( immediately at_period_end )],
                # Can also be 'none'
                proration_behavior => 'create_prorations',
            },
            subscription_pause =>
            {
                enabled => 0,
            },
            subscription_update =>
            {
                default_allowed_updates => [qw( price quantity promotion_code )],
                enabled => 1,
                products => [
                    { prices => [qw( price12345 price6789 )], product => 'prod123456789' },
                ],
                # Can also be 'none' and 'always_invoice'
                proration_behavior => 'create_prorations',
            },
        },
        is_default => 1,
        livemode => $stripe->false,
        metadata => { my_db_key => 123456789 },
    });

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A portal configuration describes the functionality and features that you want to provide to your customers through the portal.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 active boolean

Whether the configuration is active and can be used to create portal sessions.

=head2 application string

Expandable "application" (Connect only)

ID of the Connect Application that created the configuration.

=head2 business_profile hash

The business information shown to customers in the portal.

=over 4

=item * C<headline> string

The messaging shown to customers in the portal.

=item * C<privacy_policy_url> string

A link to the business’s publicly available privacy policy.

=item * C<terms_of_service_url> string

A link to the business’s publicly available terms of service.

=back

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 default_return_url string

The default URL to redirect customers to when they click on the portal’s link to return to your website. This can be overriden when creating the session.

=head2 features hash

Information about the features available in the portal.

It has the following properties:

=over 4

=item C<customer_update> hash

Information about updating customer details in the portal.

=over 8

=item C<allowed_updates> array

The types of customer updates that are supported. When empty, customers are not updateable.

=item C<enabled> boolean

Whether the feature is enabled.


=back

=item C<invoice_history> hash

Information about showing invoice history in the portal.

When expanded, this is a L<Net::API::Stripe::Payment::Installment> object.

=item C<payment_method_update> hash

Information about updating payment methods in the portal. View the list of supported payment methods in the L<docs|https://stripe.com/docs/billing/subscriptions/integrating-customer-portal#supported-payment-methods>.

When expanded, this is a L<Net::API::Stripe::Payment::Installment> object.

=item C<subscription_cancel> hash

Information about canceling subscriptions in the portal.

=over 8

=item C<cancellation_reason> hash

Whether the cancellation reasons will be collected in the portal and which options are exposed to the customer

=over 12

=item C<enabled> boolean

Whether the feature is enabled.

=item C<options> array

Which cancellation reasons will be given as options to the customer.


=back

=item C<enabled> boolean

Whether the feature is enabled.

=item C<mode> string

Whether to cancel subscriptions immediately or at the end of the billing period.

=item C<proration_behavior> string

Whether to create prorations when canceling subscriptions. Possible values are C<none> and C<create_prorations>.


=back

=item C<subscription_pause> hash

Information about pausing subscriptions in the portal.

When expanded, this is a L<Net::API::Stripe::Payment::Installment> object.

=item C<subscription_update> hash

Information about updating subscriptions in the portal.

=over 8

=item C<default_allowed_updates> array

The types of subscription updates that are supported for items listed in the C<products> attribute. When empty, subscriptions are not updateable.

=item C<enabled> boolean

Whether the feature is enabled.

=item C<products> array

The list of products that support subscription updates.

=over 12

=item C<prices> string_array

The list of price IDs which, when subscribed to, a subscription can be updated.

=item C<product> string

The product ID.


=back

=item C<proration_behavior> string

Determines how to handle prorations resulting from subscription updates. Valid values are C<none>, C<create_prorations>, and C<always_invoice>.


=back

=back

=head2 is_default boolean

Whether the configuration is the default. If true, this configuration can be managed in the Dashboard and portal sessions will use this configuration unless it is overriden when creating the session.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 login_page hash

The hosted login page for this configuration. Learn more about the portal login page in our L<integration docs|https://stripe.com/docs/billing/subscriptions/integrating-customer-portal#share>.

It has the following properties:

=over 4

=item C<enabled> boolean

If C<true>, a shareable C<url> will be generated that will take your customers to a hosted login page for the customer portal.

If C<false>, the previously generated C<url>, if any, will be deactivated.

=item C<url> string

A shareable URL to the hosted portal login page. Your customers will be able to log in with their L<email|https://stripe.com/docs/api/customers/object#customer_object-email> and receive a link to their customer portal.

=back

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 updated timestamp

Time at which the object was last updated. Measured in seconds since the Unix epoch.

=head1 API SAMPLE

    {
      "id": "bpc_1LJnbGCeyNCl6fY2uCGtb5z5",
      "object": "billing_portal.configuration",
      "active": true,
      "application": null,
      "business_profile": {
        "headline": null,
        "privacy_policy_url": "https://example.com/privacy",
        "terms_of_service_url": "https://example.com/terms"
      },
      "created": 1657411334,
      "default_return_url": null,
      "features": {
        "customer_update": {
          "allowed_updates": [
            "email",
            "tax_id"
          ],
          "enabled": true
        },
        "invoice_history": {
          "enabled": true
        },
        "payment_method_update": {
          "enabled": false
        },
        "subscription_cancel": {
          "cancellation_reason": {
            "enabled": false,
            "options": []
          },
          "enabled": false,
          "mode": "at_period_end",
          "proration_behavior": "none"
        },
        "subscription_pause": {
          "enabled": false
        },
        "subscription_update": {
          "default_allowed_updates": [],
          "enabled": false,
          "proration_behavior": "none"
        }
      },
      "is_default": true,
      "livemode": true,
      "metadata": null,
      "updated": 1657411334
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_portal/configuration>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
