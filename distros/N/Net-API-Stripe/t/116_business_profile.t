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
    use_ok( 'Net::API::Stripe::Connect::Business::Profile' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Connect::Business::Profile'" );
};
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'mcc' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'name' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'product_description' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'support_address' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'support_email' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'support_phone' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'support_url' );
can_ok( 'Net::API::Stripe::Connect::Business::Profile', 'url' );
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
my $json_file = $sample_dir->child( 'business_profile.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'business_profile'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'business_profile': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Connect::Business::Profile->new( $code ) : Net::API::Stripe::Connect::Business::Profile->new;
isa_ok( $obj => 'Net::API::Stripe::Connect::Business::Profile' );

done_testing();

__END__

