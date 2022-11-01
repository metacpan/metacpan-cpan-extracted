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
    use_ok( 'Net::API::Stripe::Balance::Transaction' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Balance::Transaction'" );
};
can_ok( 'Net::API::Stripe::Balance::Transaction', 'amount' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'available_on' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'created' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'currency' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'description' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'exchange_rate' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'fee' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'fee_details' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'id' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'net' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'object' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'reporting_category' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'source' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'status' );
can_ok( 'Net::API::Stripe::Balance::Transaction', 'type' );
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
my $json_file = $sample_dir->child( 'balance_transaction.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'balance_transaction'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'balance_transaction': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Balance::Transaction->new( $code ) : Net::API::Stripe::Balance::Transaction->new;
isa_ok( $obj => 'Net::API::Stripe::Balance::Transaction' );

done_testing();

__END__

