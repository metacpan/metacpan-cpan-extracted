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
    use_ok( 'Net::API::Stripe::Dispute::Evidence' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Dispute::Evidence'" );
};
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'access_activity_log' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'billing_address' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'cancellation_policy' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'cancellation_policy_disclosure' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'cancellation_rebuttal' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'customer_communication' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'customer_email_address' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'customer_name' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'customer_purchase_ip' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'customer_signature' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'duplicate_charge_documentation' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'duplicate_charge_explanation' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'duplicate_charge_id' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'product_description' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'receipt' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'refund_policy' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'refund_policy_disclosure' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'refund_refusal_explanation' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'service_date' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'service_documentation' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'shipping_address' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'shipping_carrier' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'shipping_date' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'shipping_documentation' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'shipping_tracking_number' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'uncategorized_file' );
can_ok( 'Net::API::Stripe::Dispute::Evidence', 'uncategorized_text' );
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
my $json_file = $sample_dir->child( 'dispute_evidence.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'dispute_evidence'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'dispute_evidence': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Dispute::Evidence->new( $code ) : Net::API::Stripe::Dispute::Evidence->new;
isa_ok( $obj => 'Net::API::Stripe::Dispute::Evidence' );

done_testing();

__END__

