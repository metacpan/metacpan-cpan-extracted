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
    use_ok( 'Net::API::Stripe::Price' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Price'" );
};
can_ok( 'Net::API::Stripe::Price', 'active' );
can_ok( 'Net::API::Stripe::Price', 'billing_scheme' );
can_ok( 'Net::API::Stripe::Price', 'created' );
can_ok( 'Net::API::Stripe::Price', 'currency' );
can_ok( 'Net::API::Stripe::Price', 'currency_options' );
can_ok( 'Net::API::Stripe::Price', 'custom_unit_amount' );
can_ok( 'Net::API::Stripe::Price', 'id' );
can_ok( 'Net::API::Stripe::Price', 'livemode' );
can_ok( 'Net::API::Stripe::Price', 'lookup_key' );
can_ok( 'Net::API::Stripe::Price', 'metadata' );
can_ok( 'Net::API::Stripe::Price', 'nickname' );
can_ok( 'Net::API::Stripe::Price', 'object' );
can_ok( 'Net::API::Stripe::Price', 'product' );
can_ok( 'Net::API::Stripe::Price', 'recurring' );
can_ok( 'Net::API::Stripe::Price', 'tax_behavior' );
can_ok( 'Net::API::Stripe::Price', 'tiers' );
can_ok( 'Net::API::Stripe::Price', 'tiers_mode' );
can_ok( 'Net::API::Stripe::Price', 'transform_quantity' );
can_ok( 'Net::API::Stripe::Price', 'type' );
can_ok( 'Net::API::Stripe::Price', 'unit_amount' );
can_ok( 'Net::API::Stripe::Price', 'unit_amount_decimal' );
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
my $json_file = $sample_dir->child( 'price.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'price'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'price': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Price->new( $code ) : Net::API::Stripe::Price->new;
isa_ok( $obj => 'Net::API::Stripe::Price' );

done_testing();

__END__

