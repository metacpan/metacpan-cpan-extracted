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
    use_ok( 'Net::API::Stripe::Billing::Subscription' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::Subscription'" );
};
can_ok( 'Net::API::Stripe::Billing::Subscription', 'application' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'application_fee_percent' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'automatic_tax' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'billing_cycle_anchor' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'billing_thresholds' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'cancel_at' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'cancel_at_period_end' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'canceled_at' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'collection_method' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'created' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'currency' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'current_period_end' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'current_period_start' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'customer' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'days_until_due' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'default_payment_method' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'default_source' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'default_tax_rates' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'description' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'discount' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'ended_at' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'id' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'items' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'latest_invoice' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'next_pending_invoice_item_invoice' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'object' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'pause_collection' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'payment_settings' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'pending_invoice_item_interval' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'pending_setup_intent' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'pending_update' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'schedule' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'start_date' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'status' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'test_clock' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'transfer_data' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'trial_end' );
can_ok( 'Net::API::Stripe::Billing::Subscription', 'trial_start' );
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
my $json_file = $sample_dir->child( 'subscription.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'subscription'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'subscription': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::Subscription->new( $code ) : Net::API::Stripe::Billing::Subscription->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::Subscription' );

done_testing();

__END__

