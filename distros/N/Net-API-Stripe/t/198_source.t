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
    use_ok( 'Net::API::Stripe::Payment::Source' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Source'" );
};
can_ok( 'Net::API::Stripe::Payment::Source', 'amount' );
can_ok( 'Net::API::Stripe::Payment::Source', 'client_secret' );
can_ok( 'Net::API::Stripe::Payment::Source', 'code_verification' );
can_ok( 'Net::API::Stripe::Payment::Source', 'created' );
can_ok( 'Net::API::Stripe::Payment::Source', 'currency' );
can_ok( 'Net::API::Stripe::Payment::Source', 'customer' );
can_ok( 'Net::API::Stripe::Payment::Source', 'flow' );
can_ok( 'Net::API::Stripe::Payment::Source', 'id' );
can_ok( 'Net::API::Stripe::Payment::Source', 'livemode' );
can_ok( 'Net::API::Stripe::Payment::Source', 'metadata' );
can_ok( 'Net::API::Stripe::Payment::Source', 'object' );
can_ok( 'Net::API::Stripe::Payment::Source', 'owner' );
can_ok( 'Net::API::Stripe::Payment::Source', 'receiver' );
can_ok( 'Net::API::Stripe::Payment::Source', 'redirect' );
can_ok( 'Net::API::Stripe::Payment::Source', 'source_order' );
can_ok( 'Net::API::Stripe::Payment::Source', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Payment::Source', 'status' );
can_ok( 'Net::API::Stripe::Payment::Source', 'type' );
can_ok( 'Net::API::Stripe::Payment::Source', 'usage' );
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
my $json_file = $sample_dir->child( 'source.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'source'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'source': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Source->new( $code ) : Net::API::Stripe::Payment::Source->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Source' );

done_testing();

__END__

