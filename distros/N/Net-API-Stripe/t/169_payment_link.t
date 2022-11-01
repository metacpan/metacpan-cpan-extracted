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
    use_ok( 'Net::API::Stripe::Payment::Link' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Link'" );
};
can_ok( 'Net::API::Stripe::Payment::Link', 'active' );
can_ok( 'Net::API::Stripe::Payment::Link', 'after_completion' );
can_ok( 'Net::API::Stripe::Payment::Link', 'allow_promotion_codes' );
can_ok( 'Net::API::Stripe::Payment::Link', 'application_fee_amount' );
can_ok( 'Net::API::Stripe::Payment::Link', 'application_fee_percent' );
can_ok( 'Net::API::Stripe::Payment::Link', 'automatic_tax' );
can_ok( 'Net::API::Stripe::Payment::Link', 'billing_address_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'consent_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'currency' );
can_ok( 'Net::API::Stripe::Payment::Link', 'customer_creation' );
can_ok( 'Net::API::Stripe::Payment::Link', 'id' );
can_ok( 'Net::API::Stripe::Payment::Link', 'line_items' );
can_ok( 'Net::API::Stripe::Payment::Link', 'livemode' );
can_ok( 'Net::API::Stripe::Payment::Link', 'metadata' );
can_ok( 'Net::API::Stripe::Payment::Link', 'object' );
can_ok( 'Net::API::Stripe::Payment::Link', 'on_behalf_of' );
can_ok( 'Net::API::Stripe::Payment::Link', 'payment_intent_data' );
can_ok( 'Net::API::Stripe::Payment::Link', 'payment_method_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'payment_method_types' );
can_ok( 'Net::API::Stripe::Payment::Link', 'phone_number_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'shipping_address_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'shipping_options' );
can_ok( 'Net::API::Stripe::Payment::Link', 'submit_type' );
can_ok( 'Net::API::Stripe::Payment::Link', 'subscription_data' );
can_ok( 'Net::API::Stripe::Payment::Link', 'tax_id_collection' );
can_ok( 'Net::API::Stripe::Payment::Link', 'transfer_data' );
can_ok( 'Net::API::Stripe::Payment::Link', 'url' );
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
my $json_file = $sample_dir->child( 'payment_link.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'payment_link'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'payment_link': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Link->new( $code ) : Net::API::Stripe::Payment::Link->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Link' );

done_testing();

__END__

