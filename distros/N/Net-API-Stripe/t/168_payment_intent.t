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
    use_ok( 'Net::API::Stripe::Payment::Intent' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Intent'" );
};
can_ok( 'Net::API::Stripe::Payment::Intent', 'amount' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'amount_capturable' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'amount_details' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'amount_received' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'application' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'application_fee_amount' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'automatic_payment_methods' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'canceled_at' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'cancellation_reason' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'capture_method' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'charges' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'client_secret' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'confirmation_method' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'created' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'currency' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'customer' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'description' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'id' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'invoice' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'last_payment_error' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'livemode' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'metadata' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'next_action' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'object' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'on_behalf_of' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'payment_method' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'payment_method_options' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'payment_method_types' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'processing' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'receipt_email' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'review' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'setup_future_usage' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'shipping' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'statement_descriptor_suffix' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'status' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'transfer_data' );
can_ok( 'Net::API::Stripe::Payment::Intent', 'transfer_group' );
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
my $json_file = $sample_dir->child( 'payment_intent.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'payment_intent'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'payment_intent': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Intent->new( $code ) : Net::API::Stripe::Payment::Intent->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Intent' );

done_testing();

__END__

