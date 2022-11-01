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
    use_ok( 'Net::API::Stripe::Checkout::Session' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Checkout::Session'" );
};
can_ok( 'Net::API::Stripe::Checkout::Session', 'after_expiration' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'allow_promotion_codes' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'amount_subtotal' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'amount_total' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'automatic_tax' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'billing_address_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'cancel_url' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'client_reference_id' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'consent' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'consent_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'currency' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'customer' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'customer_creation' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'customer_details' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'customer_email' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'expires_at' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'id' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'line_items' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'livemode' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'locale' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'metadata' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'mode' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'object' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_intent' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_link' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_method_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_method_options' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_method_types' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'payment_status' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'phone_number_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'recovered_from' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'setup_intent' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'shipping_address_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'shipping_cost' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'shipping_details' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'shipping_options' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'status' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'submit_type' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'subscription' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'success_url' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'tax_id_collection' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'total_details' );
can_ok( 'Net::API::Stripe::Checkout::Session', 'url' );
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
my $json_file = $sample_dir->child( 'checkout.session.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'checkout.session'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'checkout.session': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Checkout::Session->new( $code ) : Net::API::Stripe::Checkout::Session->new;
isa_ok( $obj => 'Net::API::Stripe::Checkout::Session' );

done_testing();

__END__

