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
    use_ok( 'Net::API::Stripe::Issuing::Card' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Issuing::Card'" );
};
can_ok( 'Net::API::Stripe::Issuing::Card', 'brand' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'cancellation_reason' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'cardholder' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'created' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'currency' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'cvc' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'exp_month' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'exp_year' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'id' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'last4' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'livemode' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'metadata' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'number' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'object' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'replaced_by' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'replacement_for' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'replacement_reason' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'shipping' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'spending_controls' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'status' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'type' );
can_ok( 'Net::API::Stripe::Issuing::Card', 'wallets' );
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
my $json_file = $sample_dir->child( 'issuing.card.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'issuing.card'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'issuing.card': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Issuing::Card->new( $code ) : Net::API::Stripe::Issuing::Card->new;
isa_ok( $obj => 'Net::API::Stripe::Issuing::Card' );

done_testing();

__END__

