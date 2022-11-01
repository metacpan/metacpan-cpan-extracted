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
    use_ok( 'Net::API::Stripe::Treasury::TransactionEntry' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Treasury::TransactionEntry'" );
};
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'balance_impact' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'created' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'currency' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'effective_at' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'financial_account' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'flow' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'flow_details' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'flow_type' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'id' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'livemode' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'object' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'transaction' );
can_ok( 'Net::API::Stripe::Treasury::TransactionEntry', 'type' );
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
my $json_file = $sample_dir->child( 'treasury.transaction_entry.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'treasury.transaction_entry'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'treasury.transaction_entry': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Treasury::TransactionEntry->new( $code ) : Net::API::Stripe::Treasury::TransactionEntry->new;
isa_ok( $obj => 'Net::API::Stripe::Treasury::TransactionEntry' );

done_testing();

__END__

