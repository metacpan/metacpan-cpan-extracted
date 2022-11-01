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
    use_ok( 'Net::API::Stripe::Charge' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Charge'" );
};
can_ok( 'Net::API::Stripe::Charge', 'amount' );
can_ok( 'Net::API::Stripe::Charge', 'amount_captured' );
can_ok( 'Net::API::Stripe::Charge', 'amount_refunded' );
can_ok( 'Net::API::Stripe::Charge', 'application' );
can_ok( 'Net::API::Stripe::Charge', 'application_fee' );
can_ok( 'Net::API::Stripe::Charge', 'application_fee_amount' );
can_ok( 'Net::API::Stripe::Charge', 'balance_transaction' );
can_ok( 'Net::API::Stripe::Charge', 'billing_details' );
can_ok( 'Net::API::Stripe::Charge', 'calculated_statement_descriptor' );
can_ok( 'Net::API::Stripe::Charge', 'captured' );
can_ok( 'Net::API::Stripe::Charge', 'created' );
can_ok( 'Net::API::Stripe::Charge', 'currency' );
can_ok( 'Net::API::Stripe::Charge', 'customer' );
can_ok( 'Net::API::Stripe::Charge', 'description' );
can_ok( 'Net::API::Stripe::Charge', 'disputed' );
can_ok( 'Net::API::Stripe::Charge', 'failure_balance_transaction' );
can_ok( 'Net::API::Stripe::Charge', 'failure_code' );
can_ok( 'Net::API::Stripe::Charge', 'failure_message' );
can_ok( 'Net::API::Stripe::Charge', 'fraud_details' );
can_ok( 'Net::API::Stripe::Charge', 'id' );
can_ok( 'Net::API::Stripe::Charge', 'invoice' );
can_ok( 'Net::API::Stripe::Charge', 'livemode' );
can_ok( 'Net::API::Stripe::Charge', 'metadata' );
can_ok( 'Net::API::Stripe::Charge', 'object' );
can_ok( 'Net::API::Stripe::Charge', 'on_behalf_of' );
can_ok( 'Net::API::Stripe::Charge', 'outcome' );
can_ok( 'Net::API::Stripe::Charge', 'paid' );
can_ok( 'Net::API::Stripe::Charge', 'payment_intent' );
can_ok( 'Net::API::Stripe::Charge', 'payment_method' );
can_ok( 'Net::API::Stripe::Charge', 'payment_method_details' );
can_ok( 'Net::API::Stripe::Charge', 'radar_options' );
can_ok( 'Net::API::Stripe::Charge', 'receipt_email' );
can_ok( 'Net::API::Stripe::Charge', 'receipt_number' );
can_ok( 'Net::API::Stripe::Charge', 'receipt_url' );
can_ok( 'Net::API::Stripe::Charge', 'refunded' );
can_ok( 'Net::API::Stripe::Charge', 'refunds' );
can_ok( 'Net::API::Stripe::Charge', 'review' );
can_ok( 'Net::API::Stripe::Charge', 'shipping' );
can_ok( 'Net::API::Stripe::Charge', 'source_transfer' );
can_ok( 'Net::API::Stripe::Charge', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Charge', 'statement_descriptor_suffix' );
can_ok( 'Net::API::Stripe::Charge', 'status' );
can_ok( 'Net::API::Stripe::Charge', 'transfer' );
can_ok( 'Net::API::Stripe::Charge', 'transfer_data' );
can_ok( 'Net::API::Stripe::Charge', 'transfer_group' );
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
my $json_file = $sample_dir->child( 'charge.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'charge'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'charge': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Charge->new( $code ) : Net::API::Stripe::Charge->new;
isa_ok( $obj => 'Net::API::Stripe::Charge' );

done_testing();

__END__

