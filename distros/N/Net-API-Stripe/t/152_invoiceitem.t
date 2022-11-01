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
    use_ok( 'Net::API::Stripe::Billing::Invoice::Item' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::Invoice::Item'" );
};
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'currency' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'customer' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'date' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'description' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'discountable' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'discounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'id' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'invoice' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'object' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'period' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'price' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'proration' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'quantity' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'subscription' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'subscription_item' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'tax_rates' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'test_clock' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'unit_amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice::Item', 'unit_amount_decimal' );
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
my $json_file = $sample_dir->child( 'invoiceitem.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'invoiceitem'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'invoiceitem': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::Invoice::Item->new( $code ) : Net::API::Stripe::Billing::Invoice::Item->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::Invoice::Item' );

done_testing();

__END__

