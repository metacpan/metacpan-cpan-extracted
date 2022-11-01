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
    use_ok( 'Net::API::Stripe::Billing::Invoice::LineItem' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::Invoice::LineItem'" );
};
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'amount' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'amount_excluding_tax' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'currency' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'description' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'discount_amounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'discountable' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'discounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'id' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'invoice_item' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'object' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'period' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'price' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'proration' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'proration_details' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'quantity' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'subscription' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'subscription_item' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'tax_amounts' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'tax_rates' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'type' );
can_ok( 'Net::API::Stripe::Billing::Invoice::LineItem', 'unit_amount_excluding_tax' );
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
my $json_file = $sample_dir->child( 'line_item.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'line_item'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'line_item': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::Invoice::LineItem->new( $code ) : Net::API::Stripe::Billing::Invoice::LineItem->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::Invoice::LineItem' );

done_testing();

__END__

