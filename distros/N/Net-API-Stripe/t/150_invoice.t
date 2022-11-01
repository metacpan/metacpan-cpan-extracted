#!perl
# This file has been automatically generated on 2022-10-12T17:14:19+0900 by scripts/check_stripe.pl.
# Any modification will be lost next time it is generated again.
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Net::API::Stripe::Billing::Invoice' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::Invoice'" );
};
can_ok( 'Net::API::Stripe::Billing::Invoice', 'account_country' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'account_name' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'account_tax_ids' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'amount_due' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'amount_paid' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'amount_remaining' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'application' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'application_fee_amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'attempt_count' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'attempted' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'auto_advance' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'automatic_tax' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'billing_reason' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'charge' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'collection_method' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'created' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'currency' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'custom_fields' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_address' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_email' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_name' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_phone' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_shipping' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_tax_exempt' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'customer_tax_ids' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'default_payment_method' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'default_source' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'default_tax_rates' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'description' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'discount' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'discounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'due_date' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'ending_balance' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'footer' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'hosted_invoice_url' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'id' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'invoice_pdf' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'last_finalization_error' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'lines' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'next_payment_attempt' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'number' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'object' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'on_behalf_of' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'paid' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'paid_out_of_band' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'payment_intent' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'payment_settings' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'period_end' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'period_start' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'post_payment_credit_notes_amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'pre_payment_credit_notes_amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'quote' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'receipt_number' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'rendering_options' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'starting_balance' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'status' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'status_transitions' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'subscription' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'subscription_proration_date' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'subtotal' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'subtotal_excluding_tax' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'tax' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'test_clock' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'threshold_reason' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'total' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'total_discount_amounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'total_excluding_tax' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'total_tax_amounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'transfer_data' );
can_ok( 'Net::API::Stripe::Billing::Invoice', 'webhooks_delivered_at' );
my $parent = file( __FILE__ )->parent;
my $sample_dir = $parent->child( 'sample' ) ||
    BAIL_OUT( $parent->error );
if( !$sample_dir->exists )
{
    BAIL_OUT( "Sample directory '${sample_dir}' does not exists." );
}
elsif( !$sample_dir->finfo->can_exec )
{
    BAIL_OUT( "Lacking permission for user $> to enter the sample directory '${sample_dir}'." );
}
my $code = {};
$code->{debug} = $DEBUG if( $DEBUG );
my $json_file = $sample_dir->child( 'invoice.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'invoice'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'invoice': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::Invoice->new( $code ) : Net::API::Stripe::Billing::Invoice->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::Invoice' );

done_testing();

__END__

