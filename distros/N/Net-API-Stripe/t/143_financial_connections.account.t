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
    use_ok( 'Net::API::Stripe::Financial::Connections::Account' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Financial::Connections::Account'" );
};
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'account_holder' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'balance' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'balance_refresh' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'category' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'created' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'display_name' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'id' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'institution_name' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'last4' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'livemode' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'object' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'ownership' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'ownership_refresh' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'permissions' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'status' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'subcategory' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'supported_payment_method_types' );
can_ok( 'Net::API::Stripe::Financial::Connections::Account', 'transaction_refresh' );
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
my $json_file = $sample_dir->child( 'financial_connections.account.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'financial_connections.account'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'financial_connections.account': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Financial::Connections::Account->new( $code ) : Net::API::Stripe::Financial::Connections::Account->new;
isa_ok( $obj => 'Net::API::Stripe::Financial::Connections::Account' );

done_testing();

__END__

