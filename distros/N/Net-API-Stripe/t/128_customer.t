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
    use_ok( 'Net::API::Stripe::Customer' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Customer'" );
};
can_ok( 'Net::API::Stripe::Customer', 'address' );
can_ok( 'Net::API::Stripe::Customer', 'balance' );
can_ok( 'Net::API::Stripe::Customer', 'cash_balance' );
can_ok( 'Net::API::Stripe::Customer', 'created' );
can_ok( 'Net::API::Stripe::Customer', 'currency' );
can_ok( 'Net::API::Stripe::Customer', 'default_source' );
can_ok( 'Net::API::Stripe::Customer', 'delinquent' );
can_ok( 'Net::API::Stripe::Customer', 'description' );
can_ok( 'Net::API::Stripe::Customer', 'discount' );
can_ok( 'Net::API::Stripe::Customer', 'email' );
can_ok( 'Net::API::Stripe::Customer', 'id' );
can_ok( 'Net::API::Stripe::Customer', 'invoice_credit_balance' );
can_ok( 'Net::API::Stripe::Customer', 'invoice_prefix' );
can_ok( 'Net::API::Stripe::Customer', 'invoice_settings' );
can_ok( 'Net::API::Stripe::Customer', 'livemode' );
can_ok( 'Net::API::Stripe::Customer', 'metadata' );
can_ok( 'Net::API::Stripe::Customer', 'name' );
can_ok( 'Net::API::Stripe::Customer', 'next_invoice_sequence' );
can_ok( 'Net::API::Stripe::Customer', 'object' );
can_ok( 'Net::API::Stripe::Customer', 'phone' );
can_ok( 'Net::API::Stripe::Customer', 'preferred_locales' );
can_ok( 'Net::API::Stripe::Customer', 'shipping' );
can_ok( 'Net::API::Stripe::Customer', 'sources' );
can_ok( 'Net::API::Stripe::Customer', 'subscriptions' );
can_ok( 'Net::API::Stripe::Customer', 'tax' );
can_ok( 'Net::API::Stripe::Customer', 'tax_exempt' );
can_ok( 'Net::API::Stripe::Customer', 'tax_ids' );
can_ok( 'Net::API::Stripe::Customer', 'test_clock' );
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
my $json_file = $sample_dir->child( 'customer.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'customer'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'customer': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Customer->new( $code ) : Net::API::Stripe::Customer->new;
isa_ok( $obj => 'Net::API::Stripe::Customer' );

done_testing();

__END__

