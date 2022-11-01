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
    use_ok( 'Net::API::Stripe::Payment::Intent::Setup' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Intent::Setup'" );
};
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'application' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'attach_to_self' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'cancellation_reason' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'client_secret' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'created' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'customer' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'description' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'flow_directions' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'id' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'last_setup_error' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'latest_attempt' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'livemode' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'mandate' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'metadata' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'next_action' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'object' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'on_behalf_of' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'payment_method' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'payment_method_options' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'payment_method_types' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'single_use_mandate' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'status' );
can_ok( 'Net::API::Stripe::Payment::Intent::Setup', 'usage' );
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
my $json_file = $sample_dir->child( 'setup_intent.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'setup_intent'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'setup_intent': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Intent::Setup->new( $code ) : Net::API::Stripe::Payment::Intent::Setup->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Intent::Setup' );

done_testing();

__END__

