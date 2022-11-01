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
    use_ok( 'Net::API::Stripe::Treasury::OutboundPayment' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Treasury::OutboundPayment'" );
};
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'amount' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'cancelable' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'created' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'currency' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'customer' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'description' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'destination_payment_method' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'destination_payment_method_details' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'end_user_details' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'expected_arrival_date' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'financial_account' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'hosted_regulatory_receipt_url' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'id' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'livemode' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'metadata' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'object' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'returned_details' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'status' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'status_transitions' );
can_ok( 'Net::API::Stripe::Treasury::OutboundPayment', 'transaction' );
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
my $json_file = $sample_dir->child( 'treasury.outbound_payment.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'treasury.outbound_payment'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'treasury.outbound_payment': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Treasury::OutboundPayment->new( $code ) : Net::API::Stripe::Treasury::OutboundPayment->new;
isa_ok( $obj => 'Net::API::Stripe::Treasury::OutboundPayment' );

done_testing();

__END__

