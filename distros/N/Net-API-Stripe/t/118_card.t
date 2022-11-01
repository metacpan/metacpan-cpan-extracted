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
    use_ok( 'Net::API::Stripe::Customer::Card' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Customer::Card'" );
};
can_ok( 'Net::API::Stripe::Customer::Card', 'account' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_city' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_country' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_line1' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_line1_check' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_line2' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_state' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_zip' );
can_ok( 'Net::API::Stripe::Customer::Card', 'address_zip_check' );
can_ok( 'Net::API::Stripe::Customer::Card', 'available_payout_methods' );
can_ok( 'Net::API::Stripe::Customer::Card', 'brand' );
can_ok( 'Net::API::Stripe::Customer::Card', 'country' );
can_ok( 'Net::API::Stripe::Customer::Card', 'currency' );
can_ok( 'Net::API::Stripe::Customer::Card', 'customer' );
can_ok( 'Net::API::Stripe::Customer::Card', 'cvc_check' );
can_ok( 'Net::API::Stripe::Customer::Card', 'dynamic_last4' );
can_ok( 'Net::API::Stripe::Customer::Card', 'exp_month' );
can_ok( 'Net::API::Stripe::Customer::Card', 'exp_year' );
can_ok( 'Net::API::Stripe::Customer::Card', 'fingerprint' );
can_ok( 'Net::API::Stripe::Customer::Card', 'funding' );
can_ok( 'Net::API::Stripe::Customer::Card', 'id' );
can_ok( 'Net::API::Stripe::Customer::Card', 'last4' );
can_ok( 'Net::API::Stripe::Customer::Card', 'metadata' );
can_ok( 'Net::API::Stripe::Customer::Card', 'name' );
can_ok( 'Net::API::Stripe::Customer::Card', 'object' );
can_ok( 'Net::API::Stripe::Customer::Card', 'tokenization_method' );
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
my $json_file = $sample_dir->child( 'card.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'card'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'card': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Customer::Card->new( $code ) : Net::API::Stripe::Customer::Card->new;
isa_ok( $obj => 'Net::API::Stripe::Customer::Card' );

done_testing();

__END__

