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
    use_ok( 'Net::API::Stripe::Issuing::Authorization' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Issuing::Authorization'" );
};
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'amount' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'amount_details' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'approved' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'authorization_method' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'balance_transactions' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'card' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'cardholder' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'created' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'currency' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'id' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'livemode' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'merchant_amount' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'merchant_currency' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'merchant_data' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'metadata' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'object' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'pending_request' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'request_history' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'status' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'transactions' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'verification_data' );
can_ok( 'Net::API::Stripe::Issuing::Authorization', 'wallet' );
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
my $json_file = $sample_dir->child( 'issuing.authorization.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'issuing.authorization'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'issuing.authorization': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Issuing::Authorization->new( $code ) : Net::API::Stripe::Issuing::Authorization->new;
isa_ok( $obj => 'Net::API::Stripe::Issuing::Authorization' );

done_testing();

__END__

