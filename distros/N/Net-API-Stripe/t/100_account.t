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
    use_ok( 'Net::API::Stripe::Connect::Account' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Connect::Account'" );
};
can_ok( 'Net::API::Stripe::Connect::Account', 'business_profile' );
can_ok( 'Net::API::Stripe::Connect::Account', 'business_type' );
can_ok( 'Net::API::Stripe::Connect::Account', 'capabilities' );
can_ok( 'Net::API::Stripe::Connect::Account', 'charges_enabled' );
can_ok( 'Net::API::Stripe::Connect::Account', 'company' );
can_ok( 'Net::API::Stripe::Connect::Account', 'controller' );
can_ok( 'Net::API::Stripe::Connect::Account', 'country' );
can_ok( 'Net::API::Stripe::Connect::Account', 'created' );
can_ok( 'Net::API::Stripe::Connect::Account', 'default_currency' );
can_ok( 'Net::API::Stripe::Connect::Account', 'details_submitted' );
can_ok( 'Net::API::Stripe::Connect::Account', 'email' );
can_ok( 'Net::API::Stripe::Connect::Account', 'external_accounts' );
can_ok( 'Net::API::Stripe::Connect::Account', 'future_requirements' );
can_ok( 'Net::API::Stripe::Connect::Account', 'id' );
can_ok( 'Net::API::Stripe::Connect::Account', 'individual' );
can_ok( 'Net::API::Stripe::Connect::Account', 'metadata' );
can_ok( 'Net::API::Stripe::Connect::Account', 'object' );
can_ok( 'Net::API::Stripe::Connect::Account', 'payouts_enabled' );
can_ok( 'Net::API::Stripe::Connect::Account', 'requirements' );
can_ok( 'Net::API::Stripe::Connect::Account', 'settings' );
can_ok( 'Net::API::Stripe::Connect::Account', 'tos_acceptance' );
can_ok( 'Net::API::Stripe::Connect::Account', 'type' );
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
my $json_file = $sample_dir->child( 'account.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'account'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'account': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Connect::Account->new( $code ) : Net::API::Stripe::Connect::Account->new;
isa_ok( $obj => 'Net::API::Stripe::Connect::Account' );

done_testing();

__END__

