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
    use_ok( 'Net::API::Stripe::Treasury::DebitReversal' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Treasury::DebitReversal'" );
};
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'amount' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'currency' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'financial_account' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'hosted_regulatory_receipt_url' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'id' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'linked_flows' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'livemode' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'metadata' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'network' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'object' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'received_debit' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'status' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'status_transitions' );
can_ok( 'Net::API::Stripe::Treasury::DebitReversal', 'transaction' );
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
my $json_file = $sample_dir->child( 'treasury.debit_reversal.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'treasury.debit_reversal'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'treasury.debit_reversal': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Treasury::DebitReversal->new( $code ) : Net::API::Stripe::Treasury::DebitReversal->new;
isa_ok( $obj => 'Net::API::Stripe::Treasury::DebitReversal' );

done_testing();

__END__

