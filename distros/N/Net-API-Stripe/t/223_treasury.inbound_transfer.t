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
    use_ok( 'Net::API::Stripe::Treasury::InboundTransfer' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Treasury::InboundTransfer'" );
};
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'amount' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'cancelable' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'created' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'currency' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'description' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'failure_details' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'financial_account' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'hosted_regulatory_receipt_url' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'id' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'linked_flows' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'livemode' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'metadata' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'object' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'origin_payment_method' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'origin_payment_method_details' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'returned' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'statement_descriptor' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'status' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'status_transitions' );
can_ok( 'Net::API::Stripe::Treasury::InboundTransfer', 'transaction' );
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
my $json_file = $sample_dir->child( 'treasury.inbound_transfer.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'treasury.inbound_transfer'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'treasury.inbound_transfer': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Treasury::InboundTransfer->new( $code ) : Net::API::Stripe::Treasury::InboundTransfer->new;
isa_ok( $obj => 'Net::API::Stripe::Treasury::InboundTransfer' );

done_testing();

__END__

