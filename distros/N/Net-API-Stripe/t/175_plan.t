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
    use_ok( 'Net::API::Stripe::Billing::Plan' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::Plan'" );
};
can_ok( 'Net::API::Stripe::Billing::Plan', 'active' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'aggregate_usage' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'amount' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'amount_decimal' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'billing_scheme' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'created' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'currency' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'id' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'interval' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'interval_count' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'nickname' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'object' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'product' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'tiers' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'tiers_mode' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'transform_usage' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'trial_period_days' );
can_ok( 'Net::API::Stripe::Billing::Plan', 'usage_type' );
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
my $json_file = $sample_dir->child( 'plan.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'plan'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'plan': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::Plan->new( $code ) : Net::API::Stripe::Billing::Plan->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::Plan' );

done_testing();

__END__

